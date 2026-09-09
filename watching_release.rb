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
        # Gem::Version.new(nil) は例外にならず 0 になるため、
        # ここで弾かないと誤った Dockerfile が選ばれ、さらに
        # Dockerfile 内の `git checkout $MRUBY_VER` が空引数となって
        # タグではなく master HEAD がビルドされてしまう。
        raise "invalid mruby version for tag '#{tag}': #{ver.inspect}" if ver.nil? || ver.to_s.empty?
        puts "buiding kishima/mruby:#{tag} (mruby #{ver})"
        using_rake = Gem::Version.new("2.1.1")
        no_bison = Gem::Version.new("2.1.2")
        rake_install = Gem::Version.new("3.2.0")
        # Debian bullseye は EOL となり、debian-security の Release ファイルが
        # 期限切れのため apt-get update が失敗する。よって新しいバージョンは
        # bookworm ベースでビルドする。
        #
        # 閾値を 3.4.0-rc としているのは、3.3.0 までは既に bullseye ベースで
        # Docker Hub に公開済みであり、当時のビルド環境をそのまま残して
        # 再現性を保つため。3.4.0 系以降（未ビルド分）から bookworm を使う。
        bookworm = Gem::Version.new("3.4.0-rc")
        mver = Gem::Version.new(ver)
        if mver < using_rake
            system("./build_image.sh #{@username}/#{@reponame} minirake.Dockerfile #{tag} #{ver}")
        elsif mver < no_bison
            system("./build_image.sh #{@username}/#{@reponame} rake_bison.Dockerfile #{tag} #{ver}")
        elsif mver < rake_install
            system("./build_image.sh #{@username}/#{@reponame} rake_nobison.Dockerfile #{tag} #{ver}")
        elsif mver < bookworm # v3.2.0以上 v3.4.0未満（bullseye、公開済みのため凍結）
            system("./build_image.sh #{@username}/#{@reponame} rake_nobison_install.Dockerfile #{tag} #{ver}")
        else # v3.4.0-rc以上
            system("./build_image.sh #{@username}/#{@reponame} rake_nobison_install_bookworm.Dockerfile #{tag} #{ver}")
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
        build_image("latest", latest_tag)
    end
end

docker = DockerWork.new
docker.build_images


