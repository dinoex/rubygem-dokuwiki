# DokuWiki

The DokuWiki library is used for automating interaction with a DokuWiki Server.

## Installation

Add this line to your application's `Gemfile`:

    gem 'dokuwiki'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dokuwiki

## Usage

    ########################
    # Example 1 Download
    ########################

    # Initialize and access the wiki at http://www.example.org/dokuwiki/
    dokuwiki = DokuWiki::DokuWikiAccess.new( 'www.example.org', '/dokuwiki' )

    # Login at specific Namespace
    dokuwiki.login( 'dir:index', username, password )

    # Download a specific Namespace
    dokuwiki.save_wiki_path( 'dir:page' )

    ########################
    # Example 2 Upload
    ########################

    # Initialize and access the wiki at http://www.example.org/
    dokuwiki = DokuWiki::DokuWikiAccess.new( 'www.example.org' )

    # Login at specific Namespace
    dokuwiki.login( 'dir:index', username, password )

    # create the cache dir
    dokuwiki.upload_dir = 'UPLOAD'
    File.mkdir( dokuwiki.upload_dir )

    # Upload a specific Namespace
    dokuwiki.upload_file( 'dir:page', 'result.pdf' )

### File formats

The extensions decides the Format used.
 '.wiki': Page in DokuWiki source
 '.txt', '.css', '.jpg', '.png', 'pdf': MediaManager file.

