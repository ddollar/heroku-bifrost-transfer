require "heroku/command"
require "tempfile"
require "uri"

module Heroku::Command
  class Bifrost < Heroku::Command::Base

    def transfer
      app = extract_app

      database_url = heroku.console(app, "puts ENV['DATABASE_URL']").to_s.strip
      bifrost_url  = heroku.config_vars(app)["BIFROST_URL"].to_s.strip

      raise(CommandFailed, "Needs DATABASE_URL") if database_url == 'nil'
      raise(CommandFailed, "Needs BIFROST_URL")  if bifrost_url  == ''

      display "initializing pgdump"
      heroku.pgdump_capture(app)
      
      display "waiting for pgdump"
      loop do
        pgdumps = heroku.pgdumps(app).sort_by { |p| Time.parse(p["created_at"]) }
        pgdump  = pgdumps.last
        break if pgdump["state"] == "captured"
        sleep 5
      end

      display "downloading pgdump"
      pgdump_url = heroku.pgdump_url(app, nil)
      tempfile = Tempfile.new("bifrost_transfer")
      system %{ curl "#{pgdump_url}" | gzip -d > "#{tempfile.path}" 2>&1 }

      display "uploading pgdump to bifrost"
      bifrost = URI.parse(bifrost_url)
      system %{ PGUSER="#{bifrost.user}" PGPASSWORD="#{bifrost.password}" psql -f #{tempfile.path} -h #{bifrost.host} #{bifrost.path[1..-1]} }
    end

  end
end