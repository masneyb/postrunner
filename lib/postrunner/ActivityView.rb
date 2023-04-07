#!/usr/bin/env ruby -w
# encoding: UTF-8
#
# = ActivityView.rb -- PostRunner - Manage the data from your Garmin sport devices.
#
# Copyright (c) 2014, 2015 by Chris Schlaeger <cs@taskjuggler.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#

require 'fit4ruby'

require 'postrunner/View'
require 'postrunner/ActivitySummary'
require 'postrunner/EventList'
require 'postrunner/DeviceList'
require 'postrunner/DataSources'
require 'postrunner/UserProfileView'
require 'postrunner/TrackView'
require 'postrunner/ChartView'

module PostRunner

  class ActivityView < View

    def initialize(activity, unit_system)
      @activity = activity
      ffs = @activity.store['file_store']
      @unit_system = unit_system

      views = ffs.views
      views.current_page = nil

      # Sort activities in reverse order so the newest one is considered the
      # last report by the pagin buttons.
      activities = ffs.activities.sort do |a1, a2|
        a1.timestamp <=> a2.timestamp
      end

      pages = PagingButtons.new(
        activities.map { |a| a.html_file_name(false) }, false)
      pages.current_page = @activity.html_file_name(false)

      super("PostRunner Activity: #{@activity.name}", views, pages)
      generate_html(@doc)
      write(@activity.html_file_name)
    end

    private

    def generate_html(doc)
      doc.unique(:activityview_style) {
        doc.head {
          [ 'jquery/jquery-3.5.1.min.js', 'flot/jquery.flot.js',
            #'flot/jquery.flot.time.js' ].each do |js|
            'flot/jquery.flot.time.js' ].each do |js|
            doc.script({ 'language' => 'javascript',
                         'type' => 'text/javascript', 'src' => js })
          end
          doc.style(style)
          doc.meta({ 'name' => 'viewport',
                     'content' => 'width=device-width, initial-scale=1.0' })
        }
      }

      body {
        doc.body {
          # The main area with the 2 column layout.
          doc.div({ :class => 'main' }) {
            doc.div({ :class => 'left_col' }) {
              ActivitySummary.new(@activity, @unit_system,
                                  { :name => @activity.name,
                                    :type => @activity.activity_type,
                                    :sub_type => @activity.activity_sub_type
                                  }).to_html(doc)
              TrackView.new(@activity).to_html(doc)
              UserProfileView.new(@activity.fit_activity, @unit_system).
                to_html(doc)
              DeviceList.new(@activity.fit_activity).to_html(doc)
            }
            doc.div({ :class => 'right_col' }) {
              ChartView.new(@activity, @unit_system).to_html(doc)
              EventList.new(@activity, @unit_system).to_html(doc)
            }
          }
          doc.div({ :class => 'two_col' }) {
            DataSources.new(@activity, @unit_system).to_html(doc)
          }
        }
      }
    end

    def style
      <<EOT
body {
  font-family: verdana,arial,sans-serif;
  margin: 0px;
}
.main {
  width: 1210px;
  margin: 0 auto;
}
.left_col {
  float: left;
  width: 600px;
}
.right_col {
  float: right;
  width: 600px;
}
.two_col {
  margin: 0 auto;
  clear: both;
  width: 1210px;
}
EOT
    end

  end

end

