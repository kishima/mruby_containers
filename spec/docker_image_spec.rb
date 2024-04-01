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

def pull_image(image_name)
    Docker::Image.create('fromImage' => image_name)
    puts "Image #{image_name} pulled successfully"
end

def run_command_in_container(image_name, command)
    pull_image(image_name)
    container = Docker::Container.create('Image' => image_name, 'Cmd' => command)
    container.start
    container.wait
    output = container.logs(stdout: true)
    container.delete(force: true)
    output.strip.force_encoding('UTF-8').encode!.gsub(/\P{Print}/, '').strip
end

github = GithubTags.new('https://api.github.com/repos/mruby/mruby/tags')

describe 'Docker Image Version Checks' do
    images = []
    tags = github.get_tags
    tags.each do |tag|
        version = tag['name']
        image_name = "kishima/mruby:#{version}"
        command = ['mruby', '-v']
        version = "3.0.0" if version == "3.0.0-preview"
        version = "2.1.2" if version == "2.1.2RC2"
        version = "2.1.2" if version == "2.1.2RC"
        version = "2.1.1" if version == "2.1.1RC2"
        version = "2.1.1" if version == "2.1.1RC"
        version.gsub!('-rc', 'RC')
        images.push({name: image_name, command: command, expected_output: version})
    end

    images.each do |image|
        context "#{image[:name]} image" do
            it "should return the correct output for #{image[:command].join(' ')}" do
                output = run_command_in_container(image[:name], image[:command])
                expect(output).to match(image[:expected_output])
            end
        end
    end
end
