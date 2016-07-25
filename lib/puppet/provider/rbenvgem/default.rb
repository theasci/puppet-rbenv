Puppet::Type.type(:rbenvgem).provide :default do
  desc "Maintains gems inside an RBenv setup"

  commands :su => 'su'

  def install
    args = ['install', '--no-rdoc', '--no-ri']
    args << "-v#{resource[:ensure]}" if !resource[:ensure].kind_of?(Symbol)
    args << [ '--source', "'#{resource[:source]}'" ] if resource[:source] != ''
    args << gem_name
    output = gem(*args)
    fail "Could not install: #{output.chomp}" if output.include?('ERROR')
  end

  def uninstall
    gem 'uninstall', '-aIx', gem_name
  end

  def latest
    @latest ||= latest_version(:remote)
  end

  def current
    latest_version
  end

  # Returns an array of versions for gem_name
  def versions(where = :local)
    args = ['list', where == :remote ? '--remote' : '--local', "^#{gem_name}$"]

		versions = []
		gem(*args).lines.map do |line|
			matches = line.match(/^(?:\S+)\s+\((.+)\)/)
			next unless matches
	    versions += matches[1].split(/,\s*/)
		end
		versions.uniq
	end

	def gem_name
		resource[:gemname]
	end

  private
    # Executes a gem command
    def gem(*args)
      exe =  "RBENV_VERSION=#{resource[:ruby]} " + resource[:rbenv] + '/bin/gem'
      su('-', resource[:user], '-c', [exe, *args].join(' '))
    end

    # Returns the highest version installed
    def latest_version(where = :local)
      all_versions = versions(where)
      return nil if all_versions.empty?

      all_versions.sort.reverse.first
    end
end
