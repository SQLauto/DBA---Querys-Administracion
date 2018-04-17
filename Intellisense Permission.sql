Intellisense not working due to insufficient security
If your Intellisense is not working, it may be that you are logged in with an insufficiently privileged user. Either of the following scripts should resolve the issue. If you only have a handful of logins or you have strict guidelines for only granting the minimum permission necessary, you can use this script.
GRANT VIEW DEFINITION TO MyUser
This one is probably overkill but if you need to fix this for alot of users at a once, it should do the trick.
GRANT EXEC ON xp_instance_regread TO public