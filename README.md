# Set up SSL for local development

	|-- Users
	|   |-- <user>
	|   |   |-- .ca
	|   |   |   |-- ca.key
	|   |   |   |-- ca.crt
	|   |   |   |-- site.key (created here)
	|   |   |   |-- site.csr (deleted when done)
	|   |   |   |-- site.crt (created here)
	|   |   |-- .local
	|   |   |   |-- bin
	|   |   |   |  |-- sign.sh
	|-- etc
	|   |-- apache2
	|   |   |-- extra
	|   |   |   |-- httpd-vhosts.conf
	|   |   |   |-- httpd-ssl.conf
	|   |   |-- ssl
	|   |   |   |-- site.key (moved here when done)
	|   |   |   |-- site.crt (moved here when done)
	|   |   |-- httpd.conf

## Resources

- About the whole process
    - [Using mod_ssl on Mac OS X](http://f.cl.ly/items/270z1h3Q2C1z0Z2R1F3U/Using%20mod_ssl%20on%20Mac%20OS%20X%20\(2013-11-02%2011-25-13%20PM\).htm) (Apple)
    - [Add https (ssl) support to your osx mac development machine with signed certificate](http://robaldred.co.uk/2009/11/adding-httpsssl-support-to-your-apache-mod_ssl-development-osx-mac-machine/) (Rob Aldred)
    - [How to easily create a SSL certificate and configure it in Apache2 in Mac OS X?](http://superuser.com/questions/73979/how-to-easily-create-a-ssl-certificate-and-configure-it-in-apache2-in-mac-os-x) (superuser)
    - [Testing Rails SSL Requirements on Your Development Machine](http://www.subelsky.com/2007/11/testing-rails-ssl-requirements-on-your.html) (Mike Subelsky)
    - [Running HTTPS in your Rails Development Environment](http://www.silverchairsolutions.com/blog/2009/09/runnning-https-in-your-rails-development-environment/)
    - [How to create a self-signed SSL Certificate which can be used for testing purposes or internal usage](http://www.akadia.com/services/ssh_test_certificate.html)
- Sign.sh
    - [sign.sh](https://www.opensource.apple.com/source/apache/apache-678/mod_ssl/pkg.contrib/sign.sh) (source)
- Weak algorithm
    - [Creating Stronger Self-Signed SSL Certificates For Testing](http://wadofstuff.blogspot.com/2012/03/creating-stronger-self-signed-ssl.html) (Matthew Flanagan)
    - [Chrome Weak Signature Algorithm](http://my.galagzee.com/2012/04/07/chrome-weak-signature-algorithm/)
    - [Chrome ‘Weak Signature Algorithm’ Solved](http://michaelwyres.com/2012/05/chrome-weak-signature-algorithm-solved/) (Michael Wyres)

## The process

Let's start out by creating a hidden directory in our home folder and we'll work from there:

	 mkdir $HOME/.ca
	 cd $HOME/.ca

### 1. Create a fake Certificate Authority (CA)

Generate a key (remember the passcode you set here):

	openssl genrsa -des3 1024 > ca.key
	
I just used the password "1234". It's not important except that you remember it. You'll need it whenever you want to sign a new certificate signing request.	
	
Now use our key to create a certificate:

	openssl req -new -x509 -days 365 -key ca.key -out ca.crt
	
Just make up the answers:

	Enter pass phrase for ca.key:
	You are about to be asked to enter information that will be incorporated
	into your certificate request.
	What you are about to enter is what is called a Distinguished Name or a DN.
	There are quite a few fields but you can leave some blank
	For some fields there will be a default value,
	If you enter '.', the field will be left blank.
	-----
	Country Name (2 letter code) [AU]:US
	State or Province Name (full name) [Some-State]:Ohio
	Locality Name (eg, city) []:
	Organization Name (eg, company) [Internet Widgits Pty Ltd]:My Fake Certificate Authority
	Organizational Unit Name (eg, section) []:
	Common Name (e.g. server FQDN or YOUR name) []:John Doe
	Email Address []:

The values between the brackets, like `[AU]` and `[Some-State]`, are defaults. As you can see I left some blank.

### 2. Inform your browser about the CA

We need to tell our browser that we trust the Certificate Authority that we fabricated. We'll do that with the **ca.crt** we created.

#### Mac OS X

##### Google Chrome

Add ca.crt to your Mac's Keychain.

- Open **Keychain Access**
- File > Import Items...
- When the dialog opens, navigate to the hidden **.ca** folder by pressing **Command + Shift + G** and entering **~/.ca**
- Choose **ca.crt** and for **Destination Keychain** choose **System** (not sure if that matters)

##### Firefox

- Firefox > Preferences...
- **Advanced** tab
- **Certificates** tab
- **View Certificated** button
- **Authorities** tab
- **Import...** button
- When the dialog opens, navigate to the hidden **.ca** folder by pressing **Command + Shift + G** and entering **~/.ca**
- Choose **ca.crt**
- Check **Trust this CA to identify websites.**

### 3. Get the signing script

We need the **sign.sh** script to sign our "Certificate Sign Requests".

#### Where to get the script

You can get that from a few places online. You can get it from [Apple's website](https://www.opensource.apple.com/source/apache/apache-678/mod_ssl/pkg.contrib/sign.sh).

Or you can get it right here:

	#!/bin/sh
	##
	##  sign.sh -- Sign a SSL Certificate Request (CSR)
	##  Copyright (c) 1998-2001 Ralf S. Engelschall, All Rights Reserved. 
	##
	
	#   argument line handling
	CSR=$1
	if [ $# -ne 1 ]; then
	    echo "Usage: sign.sign <whatever>.csr"; exit 1
	fi
	if [ ! -f $CSR ]; then
	    echo "CSR not found: $CSR"; exit 1
	fi
	case $CSR in
	   *.csr ) CERT="`echo $CSR | sed -e 's/\.csr/.crt/'`" ;;
	       * ) CERT="$CSR.crt" ;;
	esac
	
	#   make sure environment exists
	if [ ! -d ca.db.certs ]; then
	    mkdir ca.db.certs
	fi
	if [ ! -f ca.db.serial ]; then
	    echo '01' >ca.db.serial
	fi
	if [ ! -f ca.db.index ]; then
	    cp /dev/null ca.db.index
	fi
	
	#   create an own SSLeay config
	cat >ca.config <<EOT
	[ ca ]
	default_ca              = CA_own
	[ CA_own ]
	dir                     = .
	certs                   = \$dir
	new_certs_dir           = \$dir/ca.db.certs
	database                = \$dir/ca.db.index
	serial                  = \$dir/ca.db.serial
	RANDFILE                = \$dir/ca.db.rand
	certificate             = \$dir/ca.crt
	private_key             = \$dir/ca.key
	default_days            = 365
	default_crl_days        = 30
	default_md              = md5
	preserve                = no
	policy                  = policy_anything
	[ policy_anything ]
	countryName             = optional
	stateOrProvinceName     = optional
	localityName            = optional
	organizationName        = optional
	organizationalUnitName  = optional
	commonName              = supplied
	emailAddress            = optional
	EOT
	
	#  sign the certificate
	echo "CA signing: $CSR -> $CERT:"
	openssl ca -config ca.config -out $CERT -infiles $CSR
	echo "CA verifying: $CERT <-> CA cert"
	openssl verify -CAfile ca.crt $CERT
	
	#  cleanup after SSLeay 
	rm -f ca.config
	rm -f ca.db.serial.old
	rm -f ca.db.index.old
	
	#  die gracefully
	exit 0

#### Script Modifications

##### The encryption type

We have to make this change to the script or we'll get an error in the browser complaining that we used a weak algorithm.

On line 46:

	default_md              = md5
	
Modify it to use **sha512**:

	default_md              = sha512
	
##### File location

I placed **sign.sh** in my PATH:

	mv sign.sh $HOME/.local/bin

### 4. Create a Certificate Signing Request

We'll create a certificate for each site that needs SSL. For this example we'll use "example.dev" as our site name.

First create a key (just the same as the Certificate Authority key):

	openssl genrsa -des3 1024 > example.key

Again, I just used "1234" for the password.

Next we'll create the Certificate Signing Request (CSR):

	openssl req -new -key example.key > example.csr

### 5. Sign the Certificate Signing Request

You'll need the password from your **ca.key**.

Sign the CSR with our made up Certificate Authority (CA):

	sign.sh example.csr
	
This creates **example.crt**.

We should change **example.key** to not use a password now:

	mv example.key example.key.original
	openssl rsa -in example.key.original -out example.key

Cleanup

	rm example.key.original example.csr

### 6. Place certificate and key

Create a folder in the apache directory and move the files there:

	mkdir /etc/apache2/ssl
	mv example* /etc/apache2/ssl/

### 7. Set up Apache and virtual host

#### Mac OS X

In **httpd.conf** ensure these lines are uncommented:

	LoadModule ssl_module libexec/apache2/mod_ssl.so

And:

	Include /private/etc/apache2/extra/httpd-ssl.conf

In **/private/etc/apache2/extra/httpd-ssl.conf**, remove the `<VirtualHost>` block.

In **/private/etc/apache2/extra/httpd-vhosts.conf**:

	NameVirtualHost *:80
	NameVirtualHost *:443
	
	<VirtualHost *:80>
		DocumentRoot "/path/to/site"
		ServerName example.dev
		SSLEngine off
		<Directory "/path/to/site">
			Options Indexes FollowSymLinks
			AllowOverride all
			Order allow,deny
			Allow from all
		</Directory>
	</VirtualHost>
	
	<VirtualHost *:443>
		SSLEngine on
		SSLCertificateFile /etc/apache2/extra/ssl/server.crt
		SSLCertificateKeyFile /etc/apache2/extra/ssl/server.key
		DocumentRoot "/path/to/site"
		ServerName example.dev
		<Directory "/path/to/site">
			Options Indexes FollowSymLinks
			AllowOverride all
			Order allow,deny
			Allow from all
		</Directory>
	</VirtualHost>

## Simplified process

For the second time around:

	cd $HOME/.ca
	name=mysite
	openssl genrsa -des3 1024 > $name.key
	openssl req -new -key $name.key > $name.csr
	sign.sh $name.csr
	mv $name.key $name.key.original 
	openssl rsa -in $name.key.original -out $name.key
	rm $name.key.original $name.csr
	mv $name* /etc/apache2/ssl/