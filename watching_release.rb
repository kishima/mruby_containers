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

    def latest_version
        tags = get_tags
        tag_list = tags.map { |tag| tag['name'] }
        latest_version = tag_list.max_by { |version| Gem::Version.new(version) }
        puts latest_version
        latest_version
    end
end

class DockerWork
    def initialize()
        @github_tags = GithubTags.new('https://api.github.com/repos/mruby/mruby/tags')
        @username = "kishima"
        @reponame = "mruby"
        @force_build = false
    end

    def tag_exists?(tagname)
        uri = URI("https://hub.docker.com/v2/repositories/#{@username}/#{@reponame}/tags/#{tagname}/")
        response = Net::HTTP.get(uri)
        response_body = JSON.parse(response)
        response_body['name'] != nil
    end

    def build_image(tag, ver)
        puts "buiding kishima/mruby:tag"
        using_rake = Gem::Version.new("2.1.1")
        no_bison = Gem::Version.new("2.1.2")
        rake_install = Gem::Version.new("3.2.0")
        mver = Gem::Version.new(ver)
        if mver < using_rake
            system("./build_image.sh #{@username}/#{@reponame} minirake.Dockerfile #{tag} #{ver}")
        elsif mver < no_bison
            system("./build_image.sh #{@username}/#{@reponame} rake_bison.Dockerfile #{tag} #{ver}")
        elsif mver < rake_install
            system("./build_image.sh #{@username}/#{@reponame} rake_nobison.Dockerfile #{tag} #{ver}")
        else # v3.2.0以上
            system("./build_image.sh #{@username}/#{@reponame} rake_nobison_install.Dockerfile #{tag} #{ver}")
        end
        exit_code = $?.exitstatus
        raise "build error occurred" if exit_code!=0
    end

    def build_images
        tags = @github_tags.get_tags
        tags.each do |tag|
            if tag_exists?(tag['name']) and !@force_build
                puts "#{tag['name']} is already exists. skip to build."
            else
                build_image(tag['name'], tag['name'])
            end
        end
        #build latest
        latest_tag = @github_tags.latest_version
        build_image("latest", latest_tag['name'])
    end
end

docker = DockerWork.new
docker.build_images


