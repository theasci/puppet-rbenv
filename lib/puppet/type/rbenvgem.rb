# https://docs.puppet.com/guides/custom_types.html
# https://www.safaribooksonline.com/library/view/puppet-types-and/9781449339319/ch04.html
Puppet::Type.newtype(:rbenvgem) do
  desc 'A Ruby Gem installed inside an rbenv-installed Ruby'

  ensurable do
    newvalue(:present) { provider.install   }
    newvalue(:absent ) { provider.uninstall }

    newvalue(:latest) {
      provider.uninstall if provider.current
      provider.install
    }

    newvalue(/./)  do
      provider.uninstall if provider.current
      provider.install
    end

    aliasvalue :installed, :present

    defaultto :present

    def retrieve
      provider.current || :absent
    end

    # +current+ The most recent version installed
    def insync?(current)
      requested = @should.first
      versions = provider.versions

      Puppet.debug("rbenvgem - #{provider.gem_name}: current = #{current}, requested = #{requested}, provider.latest = #{provider.latest}, versions = #{versions.inspect}")

      case requested
        when :present, :installed
          current != :absent
        when :latest
          versions.include?(provider.latest)
        when :absent
          current == :absent
        when /^['"]([^\s])\s([\d\.]+)['"]$/ # e.g. "'< 2.0'", "'>= 0.4.3'"
          operand = $LAST_MATCH_INFO[1]
          requested_version = $LAST_MATCH_INFO[2]
          Puppet.debug("rbenvgem - #{provider.gem_name}: evaluating #{"'#{current}' #{operand} '#{requested_version}'"}")
          eval("'#{current}' #{operand} '#{requested_version}'")
        else
          versions.include?(requested)
      end
    end
  end

  newparam(:name) do
    desc 'Gem qualified name within an rbenv repository'
  end

  newparam(:gemname) do
    desc 'The Gem name'
  end

  newparam(:ruby) do
    desc 'The ruby interpreter version'
  end

  newparam(:rbenv) do
    desc 'The rbenv root'
  end

  newparam(:user) do
    desc 'The rbenv owner'
  end

  newparam(:source) do
    desc 'The gem source'
  end

end
