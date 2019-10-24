#!/usr/local/bin/ruby -w

# = dokuwiki.rb
#
# Author::    Dirk Meyer
# Copyright:: Copyright (c) 2018 - 2019 Dirk Meyer
# License::   Distributes under the same terms as Ruby
#
# == module DokuWiki
#
# Namespace for accessing DokuWiki
#

require 'rubygems'
require 'http-cookie'
require 'mechanize'
require 'pp'

# Module for accessing DokuWiki
module DokuWiki
  # === Class Functions
  #
  #   require 'dokuwiki"
  #
  #   DokuWiki.new( hostname, urlpath = nil )
  #   DokuWiki.media_dir
  #   DokuWiki.upload_dir
  #   DokuWiki.wait_second
  #   DokuWiki.namespace( wikipath )
  #   DokuWiki.edit_url( wikipath )
  #   DokuWiki.get( url )
  #   DokuWiki.login( wikipath, user, pass )
  #   DokuWiki.downloaded?( filename, buffer )
  #   DokuWiki.file_put_contents( filename, line, mode = 'w+' )
  #   DokuWiki.save_wiki_source( page, filename )
  #   DokuWiki.save_wiki_body( filename, url )
  #   DokuWiki.save_wiki_media( filename, url )
  #   DokuWiki.save_wiki_path( wikipath )
  #   DokuWiki.uploaded?( filename, buffer )
  #   DokuWiki.save_uploaded( filename )
  #   DokuWiki.upload_media_file?( wikipath, filename )
  #   DokuWiki.upload_wiki_file( wikipath, filename )
  #   DokuWiki.upload_file( wikipath, filename )
  #
  class DokuWikiAccess
    # extension for files in dokuwiki syntax
    EXTENSION = 'wiki'.freeze
    # filename for cookie cache
    COOKIES = 'cookies.txt'.freeze

    # directory for media download cache
    attr_accessor :media_dir
    # directory for upload cache
    attr_accessor :upload_dir

    # define server location
    def initialize( hostname, urlpath = nil )
      @site = "https://#{hostname}"
      @site << urlpath unless urlpath.nil?
      @site.freeze
      @dokuwiki_page_url = "#{@site}/doku.php?id=".freeze
      @dokuwiki_css_url = "#{@site}/lib/exe/css.php?t=".freeze
      @dokuwiki_media_url = "#{@site}/lib/exe/fetch.php?cache=&media=".freeze
      @dokuwiki_media_upload_url = "#{@site}/lib/exe/ajax.php?" \
        'tab_files=files&tab_details=view&do=media&ns='.freeze
      @media_dir = nil
      @upload_dir = nil
      @lastpage = nil
      @cookies = nil
      @sectok = nil
      @agent = nil
    end

    # be nice to the server
    def wait_second
      now = Time.now.to_i
      # p [ 'wait_second', now, $lastpage ]
      unless @lastpage.nil?
        if now <= @lastpage + 2
          sleep 2
          now = Time.now.to_i
        end
      end
      @lastpage = now
    end

    # convert path to namesape
    def namespace( wikipath )
      wikipath.gsub( ':', '%3A' ).freeze
    end

    # make edit url
    def edit_url( wikipath )
      "#{@dokuwiki_page_url}#{wikipath}&do=edit"
    end

    # make upload url
    def upload_url( wikipath, filename )
      namespace = namespace( wikipath )
      url = "#{@dokuwiki_media_upload_url}#{namespace}&sectok=#{@sectok}"
      url << '&mediaid=&call=mediaupload'
      url << "&qqfile=#{filename}&ow=true"
      url
    end

    # get url
    def get( url )
      p url
      wait_second
      @agent.get( url )
    end

    # login into DokuWiki at given path
    def login( wikipath, user, pass )
      Timeout.timeout( 300 ) do
        @agent = Mechanize.new
        @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @agent.agent.http.reuse_ssl_sessions = false
        # @agent.agent.http.ca_file = ca_path
        if @cookies.nil?
          url = @dokuwiki_page_url + wikipath
          page = get( url )
          # Submit the login form
          wait_second
          page = page.form_with( id: 'dw__login' ) do |f|
            f.field_with( name: 'u' ).value = user
            f.field_with( name: 'p' ).value = pass
            f.checkbox_with( name: 'r' ).check
          end.click_button
          f = page.forms[ 1 ]
          @sectok = f.field_with( name: 'sectok' ).value
          @agent.cookie_jar.save( COOKIES )
        else
          @agent.cookie_jar.load( COOKIES )
        end
      end
    end

    # check if downloaded file has changed
    def downloaded?( filename, buffer )
      return false unless File.exist?( filename )

      old = File.read( filename, encoding: buffer.encoding )
      return true if buffer == old

      false
    end

    # write buffer to file
    def file_put_contents( filename, buffer, mode = 'w+' )
      return if downloaded?( filename, buffer )

      File.open( filename, mode ) do |f|
        f.write( buffer )
        f.close
      end
    end

    # save wiki source to file
    def save_wiki_source( page, filename )
      f = page.form_with( id: 'dw__editform' )
      wikitext = f.field_with( name: 'wikitext' ).value.delete( "\r" )
      file_put_contents( filename, wikitext )
      button = f.button_with( name: 'do[draftdel]' )
      @agent.submit( f, button )
    end

    # save wiki body to file
    def save_wiki_body( filename, url )
      page = get( url )
      file_put_contents( filename, page.body )
    end

    # save wiki media body to file
    def save_wiki_media( filename, url )
      path =
        if @media_dir.nil?
          filename
        else
          "#{MEDIA_DIR}/#{filename}"
        end
      save_wiki_body( path, url )
    end

    # save wiki path to file
    def save_wiki_path( wikipath )
      filename = wikipath.split( ':' ).last
      case wikipath
      when /[.]jpe?g$/, /[.]png$/, /[.]pdf$/
        url = @dokuwiki_media_url + wikipath
        save_wiki_media( filename, url )
      when /[.]css$/
        url = @dokuwiki_css_url + wikipath.sub( /[.]css$/, '' )
        save_wiki_media( filename, url )
      when /[.]html$/
        url = @dokuwiki_page_url + wikipath.sub( /[.]html$/, '' )
        save_wiki_body( filename, url )
      else
        url = edit_url( wikipath )
        filename << ".#{EXTENSION}"
        page = get( url )
        save_wiki_source( page, filename )
      end
    end

    # check if uploaded file has changed
    def uploaded?( filename, buffer )
      return false if @upload_dir.nil?

      savedfile = "#{@upload_dir}/#{filename}"
      return false unless File.exist?( savedfile )

      old = File.read( savedfile, encoding: buffer.encoding )
      return true if buffer == old

      false
    end

    # save content to avoid useless edits
    def save_uploaded( filename )
      print system( "cp -pv '#{filename}' '#{@upload_dir}/'" )
    end

    # upload media file at path
    def upload_media_file( wikipath, filename, raw )
      p filename
      headers = {
        'Content-Type' => 'application/octet-stream',
        'X-File-Name' => filename
      }
      url = upload_url( wikipath, filename )
      p url
      wait_second
      pp @agent.post( url, raw, headers )
      save_uploaded( filename )
    end

    # edit wiki source at path
    def upload_wiki_file( wikipath, filename )
      raw = File.read( filename ).gsub( "\n", "\r\n" )
      basename = filename.sub( /[.]#{EXTENSION}$/, '' )
      finalpath = "#{wikipath}:#{basename}"
      page = get( edit_url( finalpath ) )
      f = page.form_with( id: 'dw__editform' )
      f.field_with( name: 'wikitext' ).value = raw
      f.field_with( name: 'summary' ).value = 'automated by qscript'
      button = f.button_with( name: 'do[save]' )
      pp @agent.submit( f, button )
      save_uploaded( filename )
    end

    # upload a file at given path
    def upload_file( wikipath, filename )
      p filename
      raw = File.read( filename )
      return if uploaded?( filename, raw )

      case filename
      when /[.]#{EXTENSION}$/
        upload_wiki_file( wikipath, filename )
      else
        upload_media_file( wikipath, filename, raw )
      end
    end
  end
end

# eof
