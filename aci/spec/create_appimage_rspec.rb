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
require_relative '../libs/create'
require_relative '../libs/metadata'

exit_status = 'Expected 0 exit Status'

describe 'grab tools' do
  it 'Fetches the latest Appimage Tools' do
    expect(
      Appimage.retrieve_tools
    ).to be(0), exit_status
  end
end

describe 'bundle_appimage' do
  it 'Creates the appimage' do
    # import gpg key
    Appimage.import_gpg
    # create the appimage
    dated_cmd = Appimage.create_cmd(Metadata::APPIMAGEFILENAME)
    dated_zsync = Appimage.create_zsync(Metadata::APPIMAGEFILENAME, Metadata::PROJECT)
    latest_cmd = Appimage.create_cmd(Metadata::LATESTAPPIMAGEFILENAME)
    latest_zsync = Appimage.create_zsync(
      Metadata::LATESTAPPIMAGEFILENAME, Metadata::PROJECT
    )
    Appimage.run_cmd(dated_cmd)
    Appimage.run_cmd(dated_zsync)
    Appimage.run_cmd(latest_cmd)
    Appimage.run_cmd(latest_zsync)
    expect(
      FileTest.exists?("/appimages/#{Metadata::APPIMAGEFILENAME}")
    ).to be(true), exit_status
    expect(
      FileTest.exists?("/appimages/#{Metadata::LATESTAPPIMAGEFILENAME}")
    ).to be(true), exit_status
  end
end
