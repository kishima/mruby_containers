require 'docker'
require 'rspec'
require 'net/http'
require 'uri'
require 'json'
require 'rubygems'


class GithubTags
    def initialize(path)
        @uri = URI(path)
        @req = Net::HTTP::Get.new(@uri)
        @req['Accept'] = 'application/vnd.github.v3+json'        
    end
    def get_tags
        res = Net::HTTP.start(@uri.hostname, @uri.port, use_ssl: @uri.scheme == 'https') do |http|
            http.request(@req)
        end
        JSON.parse(res.body)
    end
end


# Dockerイメージをpullするメソッド
def pull_image(image_name)
    Docker::Image.create('fromImage' => image_name)
    puts "Image #{image_name} pulled successfully"
end

# Dockerコンテナを起動して、コマンドを実行するメソッド
def run_container(image_name, command)
    container = Docker::Container.create('Image' => image_name, 'Cmd' => command)
    container.start
    container.wait
    output = container.logs(stdout: true)
    container.delete(force: true)
    output
end

github = GithubTags.new('https://api.github.com/repos/mruby/mruby/tags')

describe 'Docker Image' do
    context 'when running a container' do
        it 'executes a command and returns the expected output' do
            tags = github.get_tags
            tags.each do |tag|
                version = tag['name']

                image_name = "kishima/mruby:#{version}"
                command = ['mruby', '-v']

                puts "checking #{image_name}"
                pull_image(image_name)
                puts "pull done #{image_name}"
                puts "run #{image_name}"
                output = run_container(image_name, command)
                output.force_encoding('UTF-8').encode!
                output = output.gsub(/\P{Print}/, '').strip
                converted_version = version.gsub('-rc', 'RC')
                p output
                expect(output).to match("mruby #{converted_version}")
                puts "OK"
            end
        end
    end
end
