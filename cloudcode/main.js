const userinfo_path = "/auth/realms/master/protocol/openid-connect/userinfo";
const userinfo_host = "192.168.178.65";
const userinfo_port = 8443;
const httpsRequest = require('/parse-server/lib/Adapters/Auth/httpsRequest.js');

/**
 * request.params={
 *     access_token: "......",
 *     installation_id: "......"
 * }
 */
Parse.Cloud.define("openIDLogin", async (request) => {

    const response = await httpsRequest.get({
        host: userinfo_host,
        port: userinfo_port,
        path: userinfo_path,
        headers: {
            Authorization: 'Bearer ' + request.params.access_token,
        },
    });

    if(response["error"]){
        throw new Parse.Error(Parse.Error.OTHER_CAUSE, response.error);
    }

    if(response["sub"]  && response["preferred_username"] && response["email"]){

        const userQuery = new Parse.Query(Parse.User);
        userQuery.equalTo("sub", response["sub"]);

        let user = await userQuery.first({useMasterKey: true});

        if(!user){
            //create user
            user = new Parse.Object("_User");
            user.set("username", response["preferred_username"]);
            // Password is required. So a random one is set.
            // user.set("password", randomString(128));
            user.set("email", response["email"]);
            user.set("sub", response["sub"]);
            user.set("authData", {});
            await user.save(null, {useMasterKey: true});

            return {"user": user, "sessionToken": user.get("sessionToken")};
        }else{

            user.set("username", response["preferred_username"]);
            user.set("email", response["email"]);
            await user.save(null, {useMasterKey: true});

            let sessionToken = `r:${randomString(32)}`;
            let session = new Parse.Object("_Session");
            session.set("user", user);
            session.set("installationId", request.params.installation_id);
            session.set("restricted", false);
            session.set("sessionToken", sessionToken);

            await session.save(null, {useMasterKey: true});

            await session.fetch({useMasterKey: true});

            return {"user": user, "sessionToken": sessionToken};
        }
    }

    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Internal server error, while logging in using open id.");
});


function randomString(length) {
    let result           = '';
    const characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charactersLength = characters.length;
    for ( let i = 0; i < length; i++ ) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}