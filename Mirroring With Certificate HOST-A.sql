--–1.Setup Outbound connections:- Consists of creating the certificate, the endpoint ( with the certificate in the AUTHENTICATION clause)
--–and then backing up the certificate
USE master

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Clarinete2016';

CREATE CERTIFICATE [HPDB98_Cert]
WITH SUBJECT = 'AGSMS-HPD98 certificate',
START_DATE = '10/26/2016'
GO
 

CREATE ENDPOINT Endpoint_Mirroring
STATE = STARTED
AS TCP ( LISTENER_PORT=5022, LISTENER_IP = ALL)
FOR DATABASE_MIRRORING (
AUTHENTICATION = CERTIFICATE HPDB98_Cert
, ROLE = ALL);
GO
 
BACKUP CERTIFICATE HPDB98_Cert TO FILE = 'E:\HPDB98_Cert.cer'
GO


USE master;
CREATE LOGIN HPDB07_login WITH PASSWORD = 'Clarinete2016'
GO
CREATE USER HPDB07_user FOR LOGIN HPDB07_login;
GO
--Associate the certificate with the user.
CREATE CERTIFICATE HPDB07_cert
AUTHORIZATION HPDB07_user
FROM FILE = 'E:\MSSQL\HPDB07_Cert.cer'
GO
--Grant connect on the endpoint to the login
GRANT CONNECT ON ENDPOINT::Endpoint_Mirroring TO [HPDB07_login];
GO