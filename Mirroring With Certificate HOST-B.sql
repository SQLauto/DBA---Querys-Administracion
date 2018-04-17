--–1.Setup Outbound connections:- Consists of creating the certificate, the endpoint ( with the certificate in the AUTHENTICATION clause)
--–and then backing up the certificate
USE master
CREATE CERTIFICATE [HPDB07_Cert]
WITH SUBJECT = 'AGSMS-HPDB07 certificate',
START_DATE = '10/26/2016'
GO
 

CREATE ENDPOINT Endpoint_Mirroring
STATE = STARTED
AS TCP ( LISTENER_PORT=5022, LISTENER_IP = ALL)
FOR DATABASE_MIRRORING (
AUTHENTICATION = CERTIFICATE HPDB07_Cert
, ROLE = ALL);
GO
 
BACKUP CERTIFICATE HPDB07_Cert TO FILE = 'D:\HPDB07_Cert.cer'
GO

USE master;
CREATE LOGIN HPDB98_login WITH PASSWORD = 'Clarinete2016'
GO
CREATE USER HPDB98_user FOR LOGIN HPDB98_login;
GO
--Associate the certificate with the user.
CREATE CERTIFICATE HPDB98_cert
AUTHORIZATION HPDB98_user
FROM FILE = 'D:\DBA\HPDB98_Cert.cer'
GO
--Grant connect on the endpoint to the login
GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [HPDB98_login];
GO