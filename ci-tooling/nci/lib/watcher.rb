# frozen_string_literal: true
#
# Copyright (C) 2016-2017 Harald Sitter <sitter@kde.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) version 3, or any
# later version accepted by the membership of KDE e.V. (or its
# successor approved by the membership of KDE e.V.), which shall
# act as a proxy defined in Section 6 of version 3 of the license.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

require 'pp'
require 'net/smtp'

require_relative '../../lib/debian/changelog'
require_relative '../../lib/debian/uscan'
require_relative '../../lib/debian/version'
require_relative '../../lib/nci'

require 'tty-command'

module NCI
  # uses uscan to check for new upstream releases
  class Watcher
    def run
      raise 'No debain/watch found!' unless File.exist?('debian/watch')

      puts 'mangling debian/watch'
      output = ''
      File.open('debian/watch').each do |line|
        output += line.gsub(%r{download.kde.org/stable/},
                            '172.17.0.1:9191/stable/')
      end
      puts output
      File.open('debian/watch', 'w') { |file| file.write(output) }
      puts 'mangled debian/watch'

      if File.readlines('debian/watch').grep(/unstable/).any?
        puts 'Quitting watcher as debian/watch contains unstable ' \
             'and we only build stable tars in Neon'
        return
      end

      cmd = TTY::Command.new
      result = cmd.run!('uscan --report --dehs') # run! to ignore errors
      data = result.out
      puts "uscan exited (#{result}) :: #{data}"

      newer = Debian::UScan::DEHS.parse_packages(data).collect do |package|
        next nil unless package.status == Debian::UScan::States::NEWER_AVAILABLE
        package
      end.compact
      pp newer

      return if newer.empty?

      puts 'unmangle debian/watch `git checkout debian/watch`'
      system('git checkout debian/watch')

      merged = false
      if system('git merge origin/Neon/stable')
        merged = true
        newer.select! { |x| x.upstream_url.include?('stable') }
      elsif system('git merge origin/Neon/unstable')
        merged = true
        # Do not filter paths when unstable was merged. We use unstable as
        # common branch, so e.g. frameworks have only Neon/unstable but their
        # download path is http://download.kde.org/stable/frameworks/...
        # We thusly cannot kick stable.
      end
      raise 'Could not merge anything' unless merged

      newer = newer.group_by(&:upstream_version)
      newer = Hash[newer.map { |k, v| [Debian::Version.new(k), v] }]
      newer = newer.sort.to_h
      newest = newer.keys[-1]
      newest_dehs_package = newer.values[-1][0] # group_by results in an array

      puts "newest #{newest.inspect}"
      p newest_dehs_package.to_s
      raise 'No newest version found' unless newest

      version = Debian::Version.new(Changelog.new(Dir.pwd).version)
      version.upstream = newest
      version.revision = '0neon' if version.revision && !version.revision.empty?

      # FIXME: stolen from sourcer
      dch = [
        'dch',
        '--distribution', NCI.latest_series,
        '--newversion', version.to_s,
        'New release'
      ]
      # dch cannot actually fail because we parse the changelog beforehand
      # so it is of acceptable format here already.
      raise 'Failed to create changelog entry' unless system(*dch)

      # FIXME: almost code copy from sourcer_base
      # --- Unset revision from this point on, so we get the base version ---
      version.revision = nil
      something_changed = false
      Dir.glob('debian/*') do |path|
        next unless path.end_with?('changelog', 'control', 'rules')
        next unless File.file?(path)
        data = File.read(path)
        begin
          source_change = data.gsub!('${source:Version}~ciBuild', version.to_s)
          binary_change = data.gsub!('${binary:Version}~ciBuild', version.to_s)
          something_changed ||= !(source_change || binary_change).nil?
        rescue
          raise "Failed to gsub #{path}"
        end
        File.write(path, data)
      end

      system('wrap-and-sort') if something_changed

      puts 'git diff'
      system('git --no-pager diff')
      puts "git commit -a -m 'New release'"
      system("git commit -a -m 'New release'")

      if %w[BUILD_CAUSE ROOT_BUILD_CAUSE].any? { |v| ENV[v] == 'MANUALTRIGGER' }
        return
      end

      puts 'sending notification mail'
      Net::SMTP.start('pandak.kubuntu.co.uk') do |smtp|
        smtp.send_message(<<-EOF, 'jr@jriddell.org', 'nci-notify@jriddell.org')
From: Neon CI <no-reply@kde.org>
To: Neon CI Watchers <no-reply@kde.org>
Subject: [nci-notify] #{newest_dehs_package.name} new version #{newest}

#{ENV['RUN_DISPLAY_URL']}

#{newest_dehs_package.inspect}
        EOF
      end
    end
  end
end