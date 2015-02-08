require 'dispatcher'
require 'declarative_authorization'

module Fedena
  # additional methods for declarative authorization
  
  module Authorizations

    def self.attach_overrides
      Dispatcher.to_prepare :fedena do
        Authorization::AuthorizationRule.send :include, self::AuthorizationRule
        Authorization::Engine.send :include, self::Engine
        FedenaPluginLoader.load_attribute_to_auth_rules
      end
    end

    module AuthorizationRule
      def self.included (base)
        base.send :attr_accessor, :source_plugin
      end

      def matches_plugin_set? (context,priv,allowed_plugins)
        @contexts.include?(context.to_sym) and (allowed_plugins.include?(@source_plugin) or @source_plugin.nil?) and
          @privileges.include? priv.to_sym
      end

      def matches_rule? (context, priv)
        @contexts.include?(context.to_sym) and @privileges.include?(priv.to_sym)
      end

    end

    module Engine

      def self.included (base)
        base.send :attr_accessor, :roles_plugin_hash
      end
      
      def accessible_routes (routes)
        options = {:user=>Authorization.current_user}
        result = []
        routes.each do |route|
          options.merge!(:context=>route[:value][:controller])
          user, roles, privileges = user_roles_privleges_from_options(route[:value][:action], options)
          result << route and next if roles.is_a?(Array) and not (roles & @omnipotent_roles).empty?
          rules = matching_auth_rules(roles, privileges, options[:context])
          result << route unless rules.empty?
        end
        result
      end

      def school_can_access? (context,priv,allowed_plugins)
        school_can_access!(context,priv,allowed_plugins)
      rescue Authorization::NotAuthorized
        false
      end

      def school_can_access! (context,priv,allowed_plugins)
        rules = plugin_set_matching_auth_rules(context,priv,allowed_plugins)
        any_rules = any_matching_auth_rules(context,priv)
        return true if any_rules.blank?
        if rules.empty?
          raise Authorization::NotAuthorized, "No matching plugins found for #{context}, #{priv} for #{Authorization.current_user.inspect} "
        else
          true
        end
      end

      def allowed_routes (routes)
        result = []
        routes.each do |route|
          if permit? route[:value][:action],:context=>route[:value][:controller]
            result << route
          end
        end
        result
      end

      def plugin_set_matching_auth_rules(context,priv,allowed_plugins)
        @auth_rules.select {|rule| rule.matches_plugin_set? context,priv,allowed_plugins}
      end

      def any_matching_auth_rules (context,priv)
        @auth_rules.select {|rule| rule.matches_rule? context,priv}
      end

    end

    module FedenaPluginLoader
      
      def self.load_attribute_to_auth_rules
        plugin_auth_file_hash = {}
        FedenaPlugin::AVAILABLE_MODULES.each{|mod| plugin_auth_file_hash["#{Rails.root}/vendor/plugins/#{mod[:name]}/#{mod[:auth_file]}"]= mod[:name]}
        Authorization::Engine.instance.auth_rules.map do |rule|
          if plugin_auth_file_hash.keys.include? rule.source_file
            rule.source_plugin = plugin_auth_file_hash[rule.source_file]
          end
        end
        roles_plugin_hash = {}
        Authorization::Engine.instance.auth_rules.group_by(&:role).each{|k,v| roles_plugin_hash[k]=v.collect(&:source_plugin).uniq}
        Authorization::Engine.instance.roles_plugin_hash = roles_plugin_hash
      end

    end
  end
end
