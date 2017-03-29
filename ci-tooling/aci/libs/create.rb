#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Copyright (C) 2016 Scarlett Clark <sgclark@kde.org>
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
require_relative 'packages'
require 'fileutils'

module Appimage

  def self.create_appimage
    # get tools
    Dir.chdir()
    Packages.retrieve_tools(
      url: 'https://github.com/probonopd/AppImageKit/releases/download/knowngood/appimagetool-x86_64.AppImage',
      file: 'appimagetool-x86_64.AppImage'
    )
    FileUtils.chmod(0755, 'appimagetool-x86_64.AppImage', verbose: true)

    `gpg2 --import /home/jenkins/.gnupg/appimage.key`
    system('/bin/bash -x /in/tooling/ci-tooling/aci/scripts/appimagetool.sh')
  end
end
