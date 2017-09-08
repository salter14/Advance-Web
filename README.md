# CAS for Advance-Web

Here is how to get it running for Advance 2016 on Windows 2012 with IIS 8.5. The process should be similar for other versions of Advance on other IIS versions, but this combo is the only one tested so far. 

## Issues
* First login works well, but trying to log in again results in a redirect loop login.aspx, confidentiality.aspx, and default.aspx.

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
4. Edit the authentication on the app folder in the default site (if that is where the site lives) and ensure that anonymous auth is disabled and forms auth is enabled.
