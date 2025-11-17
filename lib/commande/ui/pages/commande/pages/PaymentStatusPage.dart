import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../../apps/config/theme/ColorPages.dart';
import '../../../../../apps/widgets/BottomNavBarWidget.dart';
import '../../../../../paiement/ui/pages/message/MessagePaiementReussiPage.dart';
import '../../../../../paiement/ui/pages/message/MessagePaiementEchouer.dart';
import '../../panier/PanierCtrl.dart';
import '../../../../../apps/config/api/dio_client.dart';

class PaymentStatusPage extends ConsumerStatefulWidget {
  final String systemRef;
  final String baseUrl;
  final String? customCheckStatusEndpoint; // Custom endpoint for checking payment status
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
    this.customCheckStatusEndpoint,
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
      double currentProgress = (_checkCount * 0.05).clamp(0.0, 0.90);

      _checkPaymentStatus(percent: currentProgress);
      _checkCount++;

      // Update progress (increase by 5% each check, but cap at 90% until completion)
      // 5% per check means 18 checks to reach 90%, then wait for completion
      double newProgress = (_checkCount * 0.05).clamp(0.0, 0.90);
      _updateProgress(newProgress);

      // Update status message based on progress
      _updateStatusMessageByProgress(newProgress);

      // If we've reached 90% (9 checks) and still no definitive response,
      // force completion after 2 more attempts
      if (newProgress >= 0.90 && _checkCount >= 11) {
        debugPrint('⏰ Reached 90% progress for too long, treating as timeout/failure');
        _statusTimer?.cancel();
        _handlePaymentFailure('Le paiement a expiré ou n’a pas été confirmé');
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

      // Use custom endpoint if provided, otherwise use default
      final endpoint = widget.customCheckStatusEndpoint ??
          '/eblood-connect/payment-status/checking?identifier=${widget.systemRef}&percent=$percent';

      // Use dio_client for automatic auth header injection
      final response = await getWithDio(endpoint);

      print('📡 Payment status response: ${response.statusCode}');
      print('📄 Response success: ${response.success}');
      print('📄 Response data: ${response.data}');

      if (response.success && response.data != null) {
        // Extract the actual data from IApiResponse
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData != null) {
          _handleStatusResponse(responseData);
        } else {
          print('❌ Response data is null');
          _updateStatusMessage('Vérification du statut...');
        }
      } else {
        print('❌ Error checking payment status: ${response.message}');
        _updateStatusMessage('Vérification du statut...');
      }
    } catch (e) {
      print('💥 Exception checking payment status: $e');
      _updateStatusMessage('Vérification du statut...');
    }
  }

  void _handleStatusResponse(Map<String, dynamic> response) {
    debugPrint('📊 Full payment response: $response');

    // Accept both shapes:
    // 1) Top-level API envelope: {success, message, data: {...}}
    // 2) Direct data payload: {status, state, ...}
    final message = response['message'] ?? '';
    final success = response['success'];
    final Map<String, dynamic> data = (response['data'] is Map<String, dynamic>)
        ? Map<String, dynamic>.from(response['data'] as Map)
        : Map<String, dynamic>.from(response);

    debugPrint('📊 Success field: $success');
    debugPrint('📊 Message: $message');
    debugPrint('📊 Data: $data');

    // Extract status from data object (backend now returns it there)
    String? status;
    String? failureReason;
    String? bloodRequestId;
    String? systemIdentifier;

    // Extra details for UI
    String? amountText;
    String? successRef; // Onafriq ref when available
    String? failureRef; // System reference
    List<String>? errorMessages;

    // Normalize status from either 'status' or 'state'
    status = data['status']?.toString().toLowerCase() ?? data['state']?.toString().toLowerCase();
    failureReason = data['failure_reason']?.toString();
    debugPrint('📊 Payment status from data: $status');
    if (failureReason != null) {
      debugPrint('📊 Failure reason: $failureReason');
    }

      // Amount and currency formatting
      final amountVal = data['amount'];
      final currency = data['currency']?.toString();
      if (amountVal != null && currency != null) {
        if (amountVal is num) {
          amountText = '${amountVal.toStringAsFixed(2)} $currency';
        } else {
          amountText = '${amountVal.toString()} $currency';
        }
      }

      // IDs and references
      bloodRequestId = data['blood_request_id']?.toString();
      systemIdentifier = data['blood_request_identifier']?.toString();

      // References
      successRef = data['onafriq_transaction_ref']?.toString();
      failureRef = systemIdentifier;

      // Error messages list
      final em = data['onafriq_error_messages'];
      if (em is List) {
        errorMessages = em.map((e) => e.toString()).toList();
      }

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
        case 'timeout':
          isFailure = true;
          break;
        case 'pending':
        case 'processing':
          // Continue checking - backend will handle timeout at >98%
          _updateStatusMessage('Paiement en cours de traitement...');
          return;
      }
    }

    // Check success field (boolean or string)
    if (success != null && !isSuccess && !isFailure) {
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
      _handlePaymentSuccess(
        message,
        amountText: amountText,
        ref: successRef,
        bloodRequestId: bloodRequestId,
        systemIdentifier: systemIdentifier,
      );
    } else if (isFailure) {
      debugPrint('❌ Payment confirmed as failed');
      String failureMessage = failureReason ?? message;
      if (failureMessage.isEmpty) {
        failureMessage = 'Une erreur est survenue lors du traitement de votre paiement';
      }
      _handlePaymentFailure(
        failureMessage,
        ref: failureRef,
        errorMessages: errorMessages,
      );
    } else {
      debugPrint('🔄 Payment status unclear, continuing to check...');
      _updateStatusMessage('Vérification du statut...');
    }
  }

  void _handlePaymentSuccess(String message, {String? amountText, String? ref, String? bloodRequestId, String? systemIdentifier}) {
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

    // Check if custom callback is provided (for custom success screens like address view)
    if (widget.onPaymentResult != null) {
      debugPrint('🎯 Calling onPaymentResult callback for custom success handling');
      // Call the callback after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onPaymentResult!(
            page: 1,
            title: 'payment_successful'.tr,
            message: message.isNotEmpty ? message : 'payment_processed_successfully'.tr,
            paymentSucceed: true,
          );
        }
      });
    } else {
      // Default behavior: show the built-in success screen
      debugPrint('📺 Showing default success screen');
      // Navigate to success page after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                backgroundColor: Colors.white,
                body: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.red.shade100,
                        Colors.red.shade50,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: OpsSuccessScreen(
                      message: message.isNotEmpty ? message : 'payment_processed_successfully'.tr,
                      title: 'payment_successful'.tr,
                      hidde_all_btn: false,
                      ref: ref,
                      amountText: amountText,
                      bloodRequestId: bloodRequestId,
                      systemIdentifier: systemIdentifier,
                      onClosing: () {
                        debugPrint('🔘 PaymentStatusPage (Success): onClosing callback triggered');
                        try {
                          // Navigate to main app with bottom bar using GoRouter
                          context.go('/app/MainApp');
                          debugPrint('✅ PaymentStatusPage (Success): Navigation to MainApp completed successfully');
                        } catch (e) {
                          debugPrint('❌ PaymentStatusPage (Success): GoRouter navigation error: $e');
                          // Fallback: try Navigator popUntil
                          try {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            debugPrint('✅ PaymentStatusPage (Success): Fallback navigation completed');
                          } catch (e2) {
                            debugPrint('❌ PaymentStatusPage (Success): Fallback navigation also failed: $e2');
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      });
    }
  }

  void _handlePaymentFailure(String message, {String? ref, List<String>? errorMessages}) {
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
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.red.shade100,
                      Colors.red.shade50,
                      Colors.white,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: OpsErrorScreen(
                    message: message.isNotEmpty ? message : 'payment_processing_failed'.tr,
                    title: 'payment_failed'.tr,
                    hidde_all_btn: false,
                    can_show_go_back_btn: false,
                    goBack: () {},
                    ref: ref,
                    errorMessages: errorMessages,
                    onClosing: () {
                      debugPrint('🔘 PaymentStatusPage (Failure): onClosing callback triggered');
                      try {
                        // Navigate to main app with bottom bar using GoRouter
                        context.go('/app/MainApp');
                        debugPrint('✅ PaymentStatusPage (Failure): Navigation to MainApp completed successfully');
                      } catch (e) {
                        debugPrint('❌ PaymentStatusPage (Failure): GoRouter navigation error: $e');
                        // Fallback: try Navigator popUntil
                        try {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          debugPrint('✅ PaymentStatusPage (Failure): Fallback navigation completed');
                        } catch (e2) {
                          debugPrint('❌ PaymentStatusPage (Failure): Fallback navigation also failed: $e2');
                        }
                      }
                    },
                  ),
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
    debugPrint('💭 Treating timeout as failure (backend handles final resolution)');

    // Finalize progress for UX
    _updateProgress(1.0);

    // Delegate to failure handler (no confetti, no cart clearing)
    _handlePaymentFailure('Le paiement a expiré ou n’a pas été confirmé');
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
    return PopScope(
      canPop: _isCompleted,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !_isCompleted) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade100,
                Colors.red.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Stack(
            alignment: AlignmentGeometry.topCenter,
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
