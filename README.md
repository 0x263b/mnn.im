# mnn.im
---
Simple paste bin and link shortener with an [HTTP API](http://mnn.im/api)

### Testing

	bundle install
	rake db:migrate
	rackup

### Deploy on Heroku

	heroku create <app-name>
	git push heroku master
	heroku run rake db:migrate

