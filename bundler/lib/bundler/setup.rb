# frozen_string_literal: true

require_relative "shared_helpers"

if Bundler::SharedHelpers.in_bundle?
  require_relative "../bundler"

  # this happens in Bundler.setup too, but we call it here early
  # so it can happen without being Bundler.ui.silence'd
  if Bundler.settings[:auto_install]
    Bundler.auto_install
  end

  if STDOUT.tty? || ENV["BUNDLER_FORCE_TTY"]
    begin
      Bundler.ui.silence { Bundler.setup }
    rescue Bundler::BundlerError => e
      Bundler.ui.error e.message
      Bundler.ui.warn e.backtrace.join("\n") if ENV["DEBUG"]
      if e.is_a?(Bundler::GemNotFound)
        suggested_bundle = Gem.loaded_specs["bundler"] ? "bundle" : Bundler::SharedHelpers.bundle_bin_path
        suggested_cmd = "#{suggested_bundle} install"
        original_gemfile = Bundler.original_env["BUNDLE_GEMFILE"]
        suggested_cmd += " --gemfile #{original_gemfile}" if original_gemfile
        Bundler.ui.warn "Run `#{suggested_cmd}` to install missing gems."
      end
      exit e.status_code
    end
  else
    Bundler.ui.silence { Bundler.setup }
  end

  # We might be in the middle of shelling out to rubygems
  # (RUBYOPT=-rbundler/setup), so we need to give rubygems the opportunity of
  # not being silent.
  Gem::DefaultUserInteraction.ui = nil
end
