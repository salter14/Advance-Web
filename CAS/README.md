# CAS for Advance Web

Here is how to get CAS authentication with Advance 2016 on Windows 2012 with IIS 8.5. The process should be similar for other versions of Advance on other IIS versions, but this combo is the only one tested so far. 

## Known issues
###Double login
The  double login is caused by the AuthToken cookie. Advance checks the AuthToken to see if it is set whenever you hit Advance. If the user is not logged in but the AuthToken is set, Advance kills the AuthToken cookie and the ASP.NET_SessionId cookie. Since an unathenticated user will go directly to CAS, Advance won't kill these cookies until the user enters CAS credentials. Killing the ASP.NET_SessionId cookie causes the user to be sent back to CAS. The key is to kill the AuthToken whenever possible to prevent this scenario. The AuthToken is killed by the user explicity logging out by hitting the logout.aspx page. We can easily fix one cause of the lingering AuthToken by modifying the Session.js file. Instructions are included below for this fix. However, if the user times out and the Advance window is no longer open in the browser, there is no way to kill the AuthToken and prevent the double login.

## Instructions
1. Get the CAS client. The offical project page is https://wiki.jasig.org/display/CASC/.Net+Cas+Client,
but the github page seems to be better maintained: https://github.com/apereo/dotnet-cas-client. On github, there is a link to releases. We used v1.1.0.

2. Put the DotNetCasClient.dll file into the /bin directory of Advance Web (e.g. C:⧵inetpub⧵wwwroot⧵Advance2016⧵bin)

3. Update web.config in the Advance site directory. For details on this configuration see the github page for the CAS module: https://github.com/apereo/dotnet-cas-client. Additional information can be found by googling for the web.config reference. Here are the changes we made.

   * Add to configSections:
   
   `<section name="casClientConfig" type="DotNetCasClient.Configuration.CasClientConfiguration, DotNetCasClient"/>`
   
   * Add to configuration:
   ```
   <casClientConfig
      casServerLoginUrl="https://my.cas.server.edu/cas/login"
      casServerUrlPrefix="https://my.cas.server.edu/cas/"
      serverName="https://advance.myschool.edu"
      notAuthorizedUrl="~/NotAuthorized.aspx"
      cookiesRequiredUrl="~/CookiesRequired.aspx"
      redirectAfterValidation="true"
      renew="false"
      singleSignOut="true"
      ticketValidatorName="Cas20"
      serviceTicketManager="CacheServiceTicketManager" />
   ```
   * Set athentication mode to ‘forms’ and add the forms section:
   ```
   <authentication mode="Forms">
        <forms
          loginUrl="https://my.cas.server.edu/cas/login"
          name="ASP.NET_SessionId"
          timeout="30"
          defaultUrl="~/Default.aspx"
          cookieless="UseCookies"
          slidingExpiration="true" />
    </authentication>
   ```
   * Add to system.web:
   ```
   <httpModules>
    <add name="DotNetCasClient"
         type="DotNetCasClient.CasAuthenticationModule,DotNetCasClient"/>
    </httpModules>
   ```
   * Add to system.webserver:
   ```
    <!--
       Disabled Integrated Mode configuration validation.
       This will allow a single deployment to  run on IIS 5/6 and 7+
       without errors
      -->
    <validation validateIntegratedModeConfiguration="false"/>
    <modules>
      <!--
       Remove and Add the CasAuthenticationModule into the IIS7+
       Integrated Pipeline.  This has no effect on IIS5/6.
      -->
      <remove name="DotNetCasClient"/>
      <add name="DotNetCasClient"
           type="DotNetCasClient.CasAuthenticationModule,DotNetCasClient"/>
   ```
   * In appSettings, SecurityProviderAssembly and SecurityProviderType need to be changed and SecurityProviderArgs needs to be added as follows. Note that the SecurityProviderArgs value should be set to the variable that contains the Advance user name of the person logging into CAS.
   ```
   <!--Security Parameters-->
   <add key="SecurityProviderAssembly" value="Ellucian.Advance.Security" />
   <!--WebSec Authentication Model-->
   <add key="SecurityProviderType" value="advWebServerPreauthenticated" />
   <add key="SecurityProviderArgs" value="AUTH_USER" />
   ```
4. Edit the authentication on the app folder and ensure that anonymous auth is disabled and forms auth is enabled. In our case, we have the following structure in IIS: Sites > AdvanceDev > Advance2016. The Advance2016 folder is the level to make this change on to the authentication. The AdvanceDev should still allow anonymous users to allow a redirect to the Advance2016 folder.

5. Change the session state cookie name. By default, the session state cookie name is ASP.NET_SessionId, which is the same as the name of the cookie used by forms authentication. If they are both have the same name, Advance will allow users to login the first time, but users will end up in a redirect loop when the attemping to log in any time in the future. It is also critical that the forms authentication cookie name remain ASP.NET_SessionId, as that is the name of a cookie that Advance's logout code will invalidate when the user hits the logout link. If the form authentication cookie is named something else, the logout operation will not clear the cookie, and the user will remain logged in. You can observe the cookies and test the behavior of removing one or more of them by using developer tools in your browser. For Chrome, the cookies will be in the Application tab under Storage > Cookies > (Advance server hostname).

6. To fix the double login issue when the user times out and still has the Advance Web browser window open, we need to modify the Session.js file in wwwroot/Advance2016/js. The modified function is included below. These changes send the user to the logout.aspx page when the session is about to expire, which will kill the AuthToken and cleanly log out the user. There are three changes:
   1. Change the zero in ```if (secondsUntilTimeout < 0) {``` to 20
   2. Change Session.Login() to Session.LogOut(); on the next line
   3. Add -20 to $("#SessionTimeoutSeconds").text(Math.round(secondsUntilTimeout));
   ```
   Session.PerformCheck = function () {
      // this function is firing once per minute
      // but only check for the keep alive flag at most every 10 seconds 
      if (Session.KeepAlivePending && (Math.floor(Session.SecondsUntilTimeout()) % 10 == 0)) {
          Session.KeepAlive();
      }

      var secondsUntilTimeout = Session.SecondsUntilTimeout();
      if (secondsUntilTimeout < 20) {
          Session.LogOut();
      }
      else if (!Session.WarningDismissed && secondsUntilTimeout < 60) {
          $("#SessionTimeoutSeconds").text(Math.round(secondsUntilTimeout)-20);
          if (!$("#SessionTimeoutPopup").dialog("isOpen")) {
              $("#SessionTimeoutPopup").dialog("open");
          }
      }
   };
   ```

7. To prevent the user from reaching the login.aspx page when the session times out, add the following line to the <head> of login.aspx: 
   ```
   <meta http-equiv="refresh" content="0;URL='https://advance-test.dar.udel.edu/Advance2016/default.aspx'" />
   ```


