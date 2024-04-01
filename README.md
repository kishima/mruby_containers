# mruby_containers

Making mruby docker images and pushing to Docker Hub for testing purpose.

## usage

```
docker login
ruby watching_release.rb 
```

## test

```
bundle install
rspec spec/docker_image_spec.rb
```
