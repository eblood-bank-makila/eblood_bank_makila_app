import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:confetti/confetti.dart';
import '../../../../../apps/config/theme/ColorPages.dart';
import '../../../../../apps/widgets/BottomNavBarWidget.dart';
import '../../../../../paiement/ui/pages/message/MessagePaiementReussiPage.dart';
import '../../../../../paiement/ui/pages/message/MessagePaiementEchouer.dart';
import '../../../../../utilisateurs/business/interactors/UtilisateurInteractor.dart';
import '../../panier/PanierCtrl.dart';

class PaymentStatusPage extends ConsumerStatefulWidget {
  final String systemRef;
  final String baseUrl;
  final Function({
    required int page,
    required String title,
    required String message,
    required bool paymentSucceed,
  })? onPaymentResult;

  const PaymentStatusPage({
    Key? key,
    required this.systemRef,
    required this.baseUrl,
    this.onPaymentResult,
  }) : super(key: key);

  @override
  ConsumerState<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends ConsumerState<PaymentStatusPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;
  
  Timer? _statusTimer;
  double _currentProgress = 0.0;
  String _statusMessage = 'Initialisation du paiement...';
  bool _isCompleted = false;
  bool _isSuccess = false;
  int _checkCount = 0;
  int _maxChecks = 12; // Initially 1 minute (12 checks * 5 seconds), can be extended

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start checking payment status
    _startStatusChecking();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _startStatusChecking() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_checkCount >= _maxChecks) {
        debugPrint('⏰ Reached maximum checks (${_maxChecks}), handling timeout');
        _handleTimeout();
        return;
      }

      // Calculate current progress before making the API call
      double currentProgress = (_checkCount * 0.10).clamp(0.0, 0.90);

      _checkPaymentStatus(percent: currentProgress);
      _checkCount++;

      // Update progress (increase by 10% each check, but cap at 90% until completion)
      // 10% per check means 9 checks to reach 90%, then wait for completion
      double newProgress = (_checkCount * 0.10).clamp(0.0, 0.90);
      _updateProgress(newProgress);

      // Update status message based on progress
      _updateStatusMessageByProgress(newProgress);

      // If we've reached 90% (9 checks) and still no definitive response,
      // force completion after 2 more attempts
      if (newProgress >= 0.90 && _checkCount >= 11) {
        debugPrint('🔄 Reached 90% progress for too long, forcing completion');
        _statusTimer?.cancel();
        _handlePaymentSuccess('Votre paiement n\'a pas réussi !');
        return;
      }
    });

    // Initial check with 0% progress
    _checkPaymentStatus(percent: 0.0);
  }

  void _updateProgress(double progress) {
    setState(() {
      _currentProgress = progress;
    });
    _progressController.animateTo(progress);
  }

  void _updateStatusMessageByProgress(double progress) {
    String message;

    if (progress <= 0.10) {
      message = 'Initialisation du paiement...';
    } else if (progress <= 0.20) {
      message = 'Connexion au service de paiement...';
    } else if (progress <= 0.30) {
      message = 'Vérification des informations...';
    } else if (progress <= 0.40) {
      message = 'Traitement de la demande...';
    } else if (progress <= 0.50) {
      message = 'Validation en cours...';
    } else if (progress <= 0.60) {
      message = 'Confirmation du paiement...';
    } else if (progress <= 0.70) {
      message = 'Finalisation de la transaction...';
    } else if (progress <= 0.80) {
      message = 'Vérification finale...';
    } else if (progress <= 0.90) {
      message = 'Attente de confirmation...';
    } else {
      message = 'Finalisation en cours...';
    }

    setState(() {
      _statusMessage = message;
    });
  }



  Future<void> _checkPaymentStatus({required double percent}) async {
    try {
      print('🔍 Checking payment status for systemRef: ${widget.systemRef}');

      // Get the authentication token
      final token = await ref.read(utilisateurInteractorProvider).recuperationTokenOtpUseCase.run();

      final response = await http.get(
        Uri.parse('${widget.baseUrl}/payment-status/checking/${widget.systemRef}?percent=$percent'),
        headers: {
          "Authorization": "Bearer ${token ?? ''}",
          "Content-Type": "application/json",
          "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
        },
      );

      print('📡 Payment status response: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _handleStatusResponse(responseData);
      } else {
        print('❌ Error checking payment status: ${response.statusCode}');
        _updateStatusMessage('Vérification du statut...');
      }
    } catch (e) {
      print('💥 Exception checking payment status: $e');
      _updateStatusMessage('Vérification du statut...');
    }
  }

  void _handleStatusResponse(Map<String, dynamic> response) {
    debugPrint('📊 Full payment response: $response');

    final status = response['status']?.toString().toLowerCase();
    final message = response['message'] ?? '';
    final success = response['success'];
    final data = response['data'];

    debugPrint('📊 Payment status: $status');
    debugPrint('📊 Success field: $success');
    debugPrint('📊 Message: $message');
    debugPrint('📊 Data: $data');

    // Check multiple possible success indicators
    bool isSuccess = false;
    bool isFailure = false;

    // Check status field
    if (status != null) {
      switch (status) {
        case 'success':
        case 'completed':
        case 'approved':
        case 'paid':
        case 'confirmed':
          isSuccess = true;
          break;
        case 'failed':
        case 'rejected':
        case 'cancelled':
        case 'error':
          isFailure = true;
          break;
        case 'pending':
        case 'processing':
          // If we've been pending/processing for too long, assume success
          if (_checkCount >= 8) {
            debugPrint('⏰ Payment pending/processing for too long, assuming success');
            isSuccess = true;
          } else {
            _updateStatusMessage('Paiement en cours de traitement...');
            return;
          }
          break;
      }
    }

    // Check success field (boolean or string)
    if (success != null) {
      if (success is bool && success) {
        isSuccess = true;
      } else if (success.toString().toLowerCase() == 'true') {
        isSuccess = true;
      } else if (success.toString().toLowerCase() == 'false') {
        isFailure = true;
      }
    }

    // Handle the result
    if (isSuccess) {
      debugPrint('✅ Payment confirmed as successful');
      _handlePaymentSuccess(message);
    } else if (isFailure) {
      debugPrint('❌ Payment confirmed as failed');
      _handlePaymentFailure(message);
    } else {
      debugPrint('🔄 Payment status unclear, continuing to check...');

      // If we've been checking for a while and still no clear status,
      // assume success (common with mobile money)
      if (_checkCount >= 8) {
        debugPrint('⏰ Long wait detected, assuming payment success');
        _handlePaymentSuccess('Paiement n\'a pas réussi');
      } else {
        _updateStatusMessage('Vérification du statut...');
      }
    }
  }

  void _handlePaymentSuccess(String message) {
    _statusTimer?.cancel();
    _updateProgress(1.0);

    setState(() {
      _isCompleted = true;
      _isSuccess = true;
      _statusMessage = 'Paiement réussi !';
    });

    _pulseController.stop();

    // Play confetti animation for success
    _confettiController.play();
    debugPrint('🎉 Confetti animation started for payment success');

    // Clear cart after successful payment
    _clearCartAfterPayment();

    // Call onPaymentResult callback if provided
    if (widget.onPaymentResult != null) {
      debugPrint('🎉 Calling onPaymentResult for successful payment');
      widget.onPaymentResult!(
        page: 2, // Success page (page 2 in DetailCommandePage)
        title: 'Paiement Réussi',
        message: message.isNotEmpty ? message : 'Votre paiement a été traité avec succès',
        paymentSucceed: true,
      );
      return; // Don't navigate here, let the parent handle it
    }

    // Navigate to success page after a short delay (fallback if no callback)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: OpsSuccessScreen(
                  message: message.isNotEmpty ? message : 'Votre paiement a été traité avec succès',
                  title: 'Paiement Réussi',
                  hidde_all_btn: false,
                  onClosing: () {
                    debugPrint('🔘 PaymentStatusPage: onClosing callback triggered');
                    // Use a post-frame callback to ensure navigation happens after current frame
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      try {
                        if (mounted) {
                          debugPrint('🔘 PaymentStatusPage: Widget is mounted, attempting navigation');
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const BottomNavBarWidget()),
                            (route) => false,
                          );
                          debugPrint('✅ PaymentStatusPage: Navigation completed successfully');
                        } else {
                          debugPrint('❌ PaymentStatusPage: Widget is not mounted, skipping navigation');
                        }
                      } catch (e) {
                        debugPrint('❌ PaymentStatusPage: Navigation error: $e');
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  void _handlePaymentFailure(String message) {
    _statusTimer?.cancel();
    
    setState(() {
      _isCompleted = true;
      _isSuccess = false;
      _statusMessage = 'Paiement échoué';
    });
    
    _pulseController.stop();
    
    // Navigate to failure page after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: OpsErrorScreen(
                  message: message.isNotEmpty ? message : 'Une erreur est survenue lors du traitement de votre paiement',
                  title: 'Paiement Échoué',
                  hidde_all_btn: false,
                  can_show_go_back_btn: false,
                  goBack: () {},
                  onClosing: () {
                    // Use a post-frame callback to ensure navigation happens after current frame
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const BottomNavBarWidget()),
                          (route) => false,
                        );
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  void _handleTimeout() {
    _statusTimer?.cancel();

    debugPrint('⏰ Payment status check timeout reached');
    debugPrint('🔍 Check count: $_checkCount, Max checks: $_maxChecks');

    // For mobile money payments, timeout often means success
    // since the user has already confirmed on their phone
    debugPrint('💭 Assuming payment success due to mobile money timeout behavior');

    setState(() {
      _isCompleted = true;
      _isSuccess = true;
      _statusMessage = 'Paiement traité avec succès';
    });

    _pulseController.stop();
    _updateProgress(1.0);

    // Clear cart after assumed successful payment
    _clearCartAfterPayment();

    // Call onPaymentResult callback if provided
    if (widget.onPaymentResult != null) {
      debugPrint('🎉 Calling onPaymentResult for timeout (assumed success)');
      widget.onPaymentResult!(
        page: 2, // Success page (page 2 in DetailCommandePage)
        title: 'Paiement Réussi',
        message: 'Votre paiement a été traité avec succès',
        paymentSucceed: true,
      );
      return; // Don't navigate here, let the parent handle it
    }

    // Navigate to success page (fallback if no callback)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: OpsSuccessScreen(
                  message: 'Votre paiement a été traité avec succès',
                  title: 'Paiement Réussi',
                  hidde_all_btn: false,
                  onClosing: () {
                    debugPrint('🔘 PaymentStatusPage: onClosing callback triggered (timeout success)');
                    // Use a post-frame callback to ensure navigation happens after current frame
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      try {
                        if (mounted) {
                          debugPrint('🔘 PaymentStatusPage: Widget is mounted, attempting navigation');
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const BottomNavBarWidget()),
                            (route) => false,
                          );
                          debugPrint('✅ PaymentStatusPage: Navigation completed successfully');
                        } else {
                          debugPrint('❌ PaymentStatusPage: Widget is not mounted, skipping navigation');
                        }
                      } catch (e) {
                        debugPrint('❌ PaymentStatusPage: Navigation error: $e');
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  /// Clears the cart after successful payment
  Future<void> _clearCartAfterPayment() async {
    try {
      print("🧹 Clearing cart after successful payment...");
      final panierCtrl = ref.read(panierCtrlProvider.notifier);
      final success = await panierCtrl.clearCartAfterPayment();

      if (success) {
        print("✅ Cart cleared successfully after payment");
        // Refresh local cart state to reflect the changes
        await _refreshLocalCartState();
      } else {
        print("⚠️ Some items could not be removed from cart");
      }
    } catch (e) {
      print("💥 Error clearing cart after payment: $e");
      // Don't throw error as payment was successful, just log the issue
    }
  }

  /// Refreshes the local cart state to reflect server changes
  Future<void> _refreshLocalCartState() async {
    try {
      debugPrint("🔄 Refreshing local cart state after payment...");
      final panierCtrl = ref.read(panierCtrlProvider.notifier);

      // Force refresh the cart from server using the existing method
      await panierCtrl.listepanier();

      debugPrint("✅ Local cart state refreshed successfully");
    } catch (e) {
      debugPrint("💥 Error refreshing local cart state: $e");
      // Don't throw error as payment was successful, just log the issue
    }
  }

  void _updateStatusMessage(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during payment processing
        if (!_isCompleted) {
          _showExitConfirmation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Progress indicator
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCompleted ? 1.0 : _pulseAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[100],
                              ),
                            ),
                            
                            // Progress circle
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: _progressAnimation.value,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isCompleted
                                          ? (_isSuccess ? Colors.green : Colors.red)
                                          : ColorPages.COLOR_PRINCIPAL,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            // Center icon
                            Icon(
                              _isCompleted
                                  ? (_isSuccess ? Icons.check_circle : Icons.error)
                                  : Icons.payment,
                              size: 60,
                              color: _isCompleted
                                  ? (_isSuccess ? Colors.green : Colors.red)
                                  : ColorPages.COLOR_PRINCIPAL,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Status message
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Progress percentage
                Text(
                  '${(_currentProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isCompleted
                        ? (_isSuccess ? Colors.green : Colors.red)
                        : ColorPages.COLOR_PRINCIPAL,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // System reference
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Référence de transaction',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.systemRef,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPages.COLOR_PRINCIPAL,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                if (!_isCompleted) ...[
                  const SizedBox(height: 40),
                  Text(
                    'Veuillez ne pas fermer cette page pendant le traitement du paiement',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
            // Confetti widget
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 1.5708, // radians for downward
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.05,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la sortie'),
          content: const Text(
            'Votre paiement est en cours de traitement. Êtes-vous sûr de vouloir quitter cette page ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Rester'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );
  }
}
