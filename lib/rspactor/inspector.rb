module RSpactor
  # Maps the changed filenames to list of specs to run in the next go.
  # Assumes Rails-like directory structure
  class Inspector
    EXTENSIONS = %w(rb erb builder haml rhtml rxml yml conf opts)

    def initialize(dir)
      @root = dir
    end

    def determine_spec_files(file)
      candidates = translate(file)
      candidates.reject { |candidate| candidate.index('.') }.each do |dir|
        candidates.reject! { |candidate| candidate.index("#{dir}/") == 0 }
      end
      spec_files = candidates.select { |candidate| File.exists? candidate }

      if spec_files.empty?
        $stderr.puts "doesn't exist: #{candidates.inspect}"
      end
      spec_files
    end

    # mappings for Rails are inspired by autotest mappings in rspec-rails
    def translate(file)
      file = file.sub(%r:^#{Regexp.escape(@root)}/:, '')
      candidates = []

      if spec_file?(file)
        candidates << file
      else
        spec_file = append_spec_file_extension(file)

        case file
        when %r:^app/:
          if file =~ %r:^app/controllers/application(_controller)?.rb$:
            candidates << 'controllers'
          elsif file == 'app/helpers/application_helper.rb'
            candidates << 'helpers' << 'views'
          else
            candidates << spec_file.sub('app/', '')

            if file =~ %r:^app/(views/.+\.[a-z]+)\.[a-z]+$:
              candidates << append_spec_file_extension($1)
            elsif file =~ %r:app/helpers/(\w+)_helper.rb:
              candidates << "views/#{$1}"
            elsif file =~ /_observer.rb$/
              candidates << candidates.last.sub('_observer', '')
            end
          end
        when %r:^lib/:
          candidates << spec_file
          # lib/foo/bar_spec.rb -> lib/bar_spec.rb
          candidates << candidates.last.sub($&, '')
          # lib/bar_spec.rb -> bar_spec.rb
          candidates << candidates.last.sub(%r:\w+/:, '') if candidates.last.index('/')
        when 'config/routes.rb'
          candidates << 'controllers' << 'helpers' << 'views'
        when 'config/database.yml', 'db/schema.rb'
          candidates << 'models'
        when %r:^(spec/(spec_helper|shared/.*)|config/(boot|environment(s/test)?))\.rb$:, 'spec/spec.opts'
          candidates << 'spec'
        else
          candidates << spec_file
        end
      end

      candidates.map do |candidate|
        if candidate.index('spec') == 0
          candidate
        else
          'spec/' + candidate
        end
      end
    end

    def append_spec_file_extension(file)
      if File.extname(file) == ".rb"
        file.sub(/.rb$/, "_spec.rb")
      else
        file + "_spec.rb"
      end
    end

    def spec_file?(file)
      file =~ /^spec\/.+_spec.rb$/
    end
  end
end