perfect ! let's start with create_account_with_email.
FLOW: choose account type : 'personal account', 'hospital account', 'blood bank account'.

for 'personal account' use the same flow as in : eblood_bank_makila_connect with extra info :  city (this is a selection, data from backend)

for 'hospital account':
-hospital name,email, phone number,adress, city (this is a selection, data from backend),longitude, latitude, contact person :{first_name, last_name,gender,email,phone number}, admin account:{first_name,last_name,gender,email, phone number, username,password}

for 'blood bank account':
-blood bank name,email, phone number,adress, city (this is a selection, data from backend),longitude, latitude, contact person :{first_name, last_name,gender,email,phone number}, admin account:{first_name,last_name,gender,email, phone number, username,password}





perfect ! let's now enchance user experience. in 'information de contact' section can you put  'votre localisation' first before email and phone number, and show phone number input only after location is selected. because we have to use country code as phone number input leading prefix.
Note: we have also, country flag. 
