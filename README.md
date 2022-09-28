
# Table of Contents

0.  [cellxgene proxy backstory](#manualedit0)
1.  [cellxgene proxy setup](#org8535249)
    1.  [etc/cellxgene_templates](#org70b949b)
        1.  [group_to_port.map defines group to port location](#org2593de5)
        2.  [mkcellxgene_config.pl](#org9d9afed)
        3.  [apache2 template](#orga8e4ab3)
        4.  [systemd.service template:](#org2413369)
    2.  [var/www/](#org90a423a)
    3.  [etc/apache2 - apache2 configs](#org352083b)
    4.  [cellxgene && cellxgene-gateway](#org0b8bc08)
    5.  [Basic usage](#orgbaa67c6)
    6.  [links](#orga301c60)


<a id="manualedit0"></a>

# cellxgene proxy backstory

CZ CELLxGENE is an interactive data explorer for single-cell datasets.
Leveraging modern web development techniques to enable fast visualizations allowing computational researchers to explore their data.

Cellxgene Gateway allows you to use the Cellxgene Server provided by the Chan Zuckerberg Institute (<https://github.com/chanzuckerberg/cellxgene>) with multiple datasets.
It displays an index of available h5ad (anndata) files.
When a user clicks on a file name, it launches a Cellxgene Server instance that loads that particular data file and once it is available proxies requests to that server.

Now imagine, you have a number of groups who would like to use cellxgene on their data.

An obvious solution - different cellxegen-gateway instances. However a better option is to have a single instance with some kind of authentication
for different datasets/cellgene-gateway instances.

The global picture:

A group has a directory with a number of h5ad files

A cellxgene-gateway instance listening on a specific TCP port serving a specific directory with h5ad files
This is configured via cellxgene-gateway variables, such as CELLXGENE_DATA and GATEWAY_PORT

For multiple groups we have multiple cellxgene-gateway instances listening on different ports and serving different directories.
So there is a plain mapping between a group and a network port.

Now, if we add a reverse proxy on top of this configuration and create separate configs proxying requests from specific groups to specific
cellxgene-gateway instances we will have a single interface for all groups.
Also we can enable authentication for the group URLs and this allows the group based access to the data.

This repostory provides templates and a script which parses the templates and creates config files for cellxgene-gateway and apache2 reverse proxy.


<a id="org8535249"></a>

# cellxgene proxy setup

This setup provides example files and short description for setting up apache2 reverse proxy with
authentication based on mod_auth_form for cellxgene_gateway processes listening on the current or remote hosts.


<a id="org70b949b"></a>

## etc/cellxgene_templates


<a id="org2593de5"></a>

### group_to_port.map defines group to port location


<a id="org9d9afed"></a>

### mkcellxgene_config.pl

-   script which reads etc/cellxgene/group_to_port.map file and templates and generates systemd, apache2 configs
    and updates html page for apache's mod_auth_form module
-   deletetion is not implemented
-   runs in root context, since it will write systemd and apache configs


<a id="orga8e4ab3"></a>

### apache2 template

-   Ldap auth part is optional, this setup is using Openldap and groups with memberUid attribute.
    The <RequireAny/RequireAll> stanza allows users from different groups access only their cellxgene locations.
    The group sysop and defined users can access any resource.
-   See etc/apache2/sites-available/public.conf for the simplest config without authentication.


<a id="org2413369"></a>

### systemd.service template:

-   needs properly defined user and a number of ENV variables.
-   `<group>` and `<port>` will be updated by the mkcellxgene_config.pl script
-   One might need to call  `systemctl enable cellxgene_<group>` to make services start on boot


<a id="org90a423a"></a>

## var/www/

-   html and css files for mod_auth_form
-   contains the main index.html updated by `mkcellxgene_config.pl`


<a id="org352083b"></a>

## etc/apache2 - apache2 configs

-   list of enabled modules (in addition to the default ones) ( you might have different preferences!)
    `ssl,rewrite,headers,ldap,session,authnz_ldap,request,session_cookie,session_crypto,proxy,proxy_http,proxy_html`
-   sites-available/cellxgene.conf - the main config for http and https virtualhosts, also handles the logout action
    includes cellxgene/\* dir with group configs generated by `mkcellxgene_config.pl`
-   public.conf for the public section


<a id="org0b8bc08"></a>

## cellxgene && cellxgene-gateway

-   it is assumed that cellxgene and cellxgene-gateway are installed in the cellxgeneUser home dir


<a id="orgbaa67c6"></a>

## Basic usage

1.  Create the data directory for the new group and set appropirate permissions.
    (see the CELLXGENE_DATA var in the systemd template)
2.  Update /etc/cellxgene_templates/group_to_port.map
3.  Call `/etc/cellxgene_templates/mkcellxgene_config.pl <group>` to setup systemd, apache2 config
    and /var/www/index.html
4.  Start the new systemd service: `service cellxgene_<group> start`
5.  Reload apache2 config: service apache2 reload
6.  Navigate to the url and test the application
7.  Debug errors with `journalctl -xe` and (or) apache2 error log files


<a id="orga301c60"></a>

## Links

-   cellxgene: <https://github.com/chanzuckerberg/cellxgene>
-   cellxgene-gateway: <https://github.com/Novartis/cellxgene-gateway>
-   mod_auth_form: <https://httpd.apache.org/docs/current/mod/mod_auth_form.html>

