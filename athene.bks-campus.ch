server {
	listen 80;
	server_name athene.bks-campus.ch;
	
	root /var/www/new-tool/public;
	
	passenger_enabled on;
	passenger_ruby /usr/share/rvm/gems/ruby-2.6.0/wrappers/ruby
}
