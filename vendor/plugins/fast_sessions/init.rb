require File.dirname(__FILE__) + '/lib/ar_helpers'
require File.dirname(__FILE__) + '/lib/fast_sessions'

ActiveRecord::SessionStore.session_class = CGI::Session::ActiveRecordStore::FastSessions

