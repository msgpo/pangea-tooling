# frozen_string_literal: true
#
# Copyright (C) 2016-2018 Harald Sitter <sitter@kde.org>
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

require_relative 'log/cmake'
require_relative 'log/dh_missing'
require_relative 'log/lintian'
require_relative 'log/list_missing'

module Lint
  # Lints a build log
  class Log
    attr_reader :log_data

    def initialize(log_data)
      @log_data = log_data
    end

    # @return [Array<Result>]
    def lint
      results = []
      [CMake, Lintian, ListMissing, DHMissing].each do |klass|
        results << klass.new.lint(@log_data.clone)
      end
      results
    end
  end
end
