require 'net/ldap' # gem install net-ldap
require 'yaml'

module Sinatra
  module ADAuth

    VERSION="0.25.20120401"
    
    module Helpers
      def authorized?
        session[:authorized]
      end

      def authorize!
        redirect '/login' unless authorized?
      end

      def logout!
        session[:authorized] = false
      end
    end
    
    def self.registered(app)
      app.helpers ADAuth::Helpers
      app.enable :sessions
    end
    
    class User
      ### BEGIN CONFIGURATION ###

      # ATTR_SV is for single valued attributes only. Generated readers will
      # convert the value to a string before returning or calling your Proc.
      ATTR_SV = {
        :login => :samaccountname,
        :first_name => :givenname,
        :last_name => :sn,
        :email => :mail
      }


      # ATTR_MV is for multi-valued attributes. Generated readers will always 
      # return an array.
      ATTR_MV = {
        :groups => [ :memberof,
          # Get the simplified name of first-level groups.
          # TODO: Handle escaped special characters
          Proc.new {|g| g.sub(/.*?CN=(.*?),.*/, '\1')} ]
      }

      # Exposing the raw Net::LDAP::Entry is probably overkill, but could be set
      # up by uncommenting the line below if you disagree.
      # attr_reader :entry

      ### END CONFIGURATION ###


      # Automatically fail login if login or password are empty. Otherwise, try
      # to initialize a Net::LDAP object and call its bind method. If successful,
      # we find the LDAP entry for the user and initialize with it. Returns nil
      # on failure.
      def self.authenticate(login, pass, conf_file=nil)
        return nil if login.empty? or pass.empty?

        if ! self.read_conf(conf_file)
          return nil
        end
        conn = Net::LDAP.new :host => @@server,
          :port => @@port,
          :base => @@base,
          :auth => { :username => "#{login}@#{@@domain}",
            :password => pass,
            :method => :simple }
        if conn.bind and user = conn.search(:filter => "sAMAccountName=#{login}").first
          return self.new(user)
        else
          return nil
        end
        # If we don't rescue this, Net::LDAP is decidedly ungraceful about failing
        # to connect to the server. We'd prefer to say authentication failed.
      rescue Net::LDAP::LdapError => e
        return nil
      end

      def full_name
        self.first_name + ' ' + self.last_name
      end
      def name
        self.first_name.gsub("[", "").gsub("]", "").gsub("\"", "")
      end

      def member_of?(group)
        self.groups.include?(group)
      end

      private

      def initialize(entry)
        @entry = entry
        self.class.class_eval do
          generate_single_value_readers
          generate_multi_value_readers
        end
      end

      def self.generate_single_value_readers
        ATTR_SV.each_pair do |k, v|
          val, block = Array(v)
          define_method(k) do
            if @entry.attribute_names.include?(val)
              if block.is_a?(Proc)
                return block[@entry.send(val).to_s]
              else
                return @entry.send(val).to_s
              end
            else
              return ''
            end
          end
        end
      end

      def self.generate_multi_value_readers
        ATTR_MV.each_pair do |k, v|
          val, block = Array(v)
          define_method(k) do
            if @entry.attribute_names.include?(val)
              if block.is_a?(Proc)
                return @entry.send(val).collect(&block)
              else
                return @entry.send(val)
              end
            else
              return []
            end
          end
        end
      end

      # Read connection details found in YAML configuration file that is hardcoded
      def self.read_conf(conf=nil)
        (conf.nil?) ? filename = 'ldap.yaml' : filename = conf
        config= YAML.load_file(filename)
        @@server=config['ldap']['server']
        @@port=config['ldap']['port']
        @@base=config['ldap']['base']
        @@domain=config['ldap']['domain']
        true
      rescue Exception => e
        puts e.to_s
        false
      end

    end
  
  end
  
  register ADAuth
  
end

