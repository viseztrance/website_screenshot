#
# = website_screenshot.rb - Takes screenshots of webpages
#
# Author:: Daniel Mircea daniel@viseztrance.com
# Copyright:: Copyright (c) 2011 Daniel Mircea
# License:: MIT and/or Creative Commons Attribution-ShareAlike

require "rubygems"
require "Qt4"
require "qtwebkit"
require "mini_magick"

class WebsiteScreenshot

  VERSION = Gem::Specification.load(File.expand_path("../website_screenshot.gemspec", File.dirname(__FILE__))).version.to_s

  @@state      = "waiting"
  @@progress   = 0
  @@started_at = nil

  # Timeout before killing the page.
  attr_accessor :render_timeout

  attr_accessor :check_loading_status_interval #:nodoc:

  # Filename to save the file to.
  attr_accessor :file_name

  # Window size.
  attr_accessor :size

  # Page url.
  attr_accessor :url

  attr_accessor :verbose #:nodoc:
  
  # Resize image after capture
  attr_accessor :image_resize

  # Instantiates a new object.
  # ==== Options:
  # [*url*] Website path. URL redirects are automatically resolved using +curl+.
  # [*file_name*] Name of the saved image. Defaults to output.png.
  # [*render_timeout*] Timeout before killing the page. Defaults at two minutes.
  # [*check_loading_status_interval*] Interval between page status checks.
  # [*size*] Window size the page is being rendered into. Defaults at 1360x768.
  # [*verbose*] Outputs page load progress.
  # [*image_resize*] Resizes the image after capture.
  def initialize(args)
    self.render_timeout                = args[:render_timeout] || 120
    self.check_loading_status_interval = args[:check_loading_status_interval] || 0.1
    self.url                           = args[:url]
    self.file_name                     = args[:file_name] || "output.png"
    self.size                          = args[:size] || "1024x768"
    self.verbose                       = args[:verbose] # default FALSE
    self.image_resize                  = args[:image_resize] || "100%"
  end

  # Renders the website and saves a screenshot.
  # ==== Returns:
  # * If the webpage began rendering, the load percentage. A screenshot is saved if the page has been +50%+ loaded or more.
  # * +false+ if for some reason the +url+ could not be opened, or the browser initialized.
  def get

    app = Qt::Application.new(ARGV)
    webview = Qt::WebView.new()

    webview.connect(SIGNAL("loadStarted()")) do
      @@started_at = Time.now.to_i
    end

    webview.connect(SIGNAL("loadFinished(bool)")) do |result|
      if result
        @@state = "finished-success"
      else
        @@state = "finished-fail"
        @@progress = false
      end
      suspend_thread # Give it enough time to switch to the sentinel thread and avoid an empty exec loop.
    end

    webview.connect(SIGNAL("loadProgress(int)")) do |progress|
      puts "#{progress}%" if verbose
      @@progress = progress
      suspend_thread if has_reached_time_out?
    end

    # Enable flash, javascript and some other sensible browsing options.
    webview::settings()::setAttribute(Qt::WebSettings::PluginsEnabled, false)
    webview::settings()::setAttribute(Qt::WebSettings::JavascriptCanOpenWindows, false)
    webview::settings()::setAttribute(Qt::WebSettings::PrivateBrowsingEnabled, true)
    webview::settings()::setAttribute(Qt::WebSettings::JavascriptEnabled, true)

    # Hide the scrollbars.
    webview.page.mainFrame.setScrollBarPolicy(Qt::Horizontal, Qt::ScrollBarAlwaysOff)
    webview.page.mainFrame.setScrollBarPolicy(Qt::Vertical, Qt::ScrollBarAlwaysOff)

    webview.load(Qt::Url.new(url))
    webview.resize(size)
    webview.show
    render_page_thread = Thread.new do
      app.exec
    end

    check_status_thread = Thread.new do
      while true do
        sleep check_loading_status_interval
        if @@state =~ /^finished/ || has_reached_time_out?
          # Save a screenshot if page finished loaded or it has timed out with 50%+ completion.
          save(webview) if @@state == "finished-success" || @@progress >= 50
          render_page_thread.kill
          break
        end
      end
    end

    check_status_thread.join
    render_page_thread.join

    return @@progress

  end

  # Sets the window size.
  #
  # The geometry must have the following format: _widthxheight_.
  # ==== Returns:
  # A Qt::Size object.
  def size=(geometry)
    geometry_information = geometry.split("x")
    @size = Qt::Size.new(geometry_information.first.to_i, geometry_information.last.to_i)
  end

  # Sets the website url.
  #
  # Calls the operating systems +curl+ command to follow redirects.
  def url=(path)
    @url = %x[curl "#{path}" -A "Mozilla/5.0 (QtWebkit; WebsiteScreenshot)" -L -o /dev/null -w %{url_effective}]
  end

  private

  def has_reached_time_out?
    Time.now.to_i >= (@@started_at + render_timeout)
  end

  def suspend_thread
    sleep(30)
  end

  def save(webview)
    sleep(5) # Wait a few seconds to allow some/any of the animations to take place
    pixmap = Qt::Pixmap.grabWindow(webview.window.winId)
    pixmap.save(file_name, File.extname(file_name).tr(".",""))
    image = MiniMagick::Image.open(file_name)
    image.resize(image_resize)
    image.write(file_name)
  end

end
