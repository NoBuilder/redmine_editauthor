module RedmineEditauthor
  PLUGIN_ID ||= :redmine_editauthor

  PATCHES ||= [
    'Issue'
  ]

  module Settings
    class << self
      def defaults
        Redmine::Plugin.find(PLUGIN_ID).settings[:default] || {}
      end

      def method_missing(method_name)
        s = Setting.method("plugin_#{PLUGIN_ID}")

        name = method_name.to_s.sub('?', '')

        if defaults.include?(name)
          m = {}
          value = defaults[name]

          case value
          when Array
            m[name] = proc { s.call[name] || value }
            m["#{name}?"] = proc { (s.call[name] || value).any? }
          when Integer
            m[name] = proc { v = s.call[name]; v.present? ? v.to_i : value }
          when TrueClass, FalseClass
            p = proc { v = s.call[name]; v ? (!!v == v ? v : v.to_i > 0) : value }
            m[name] = p
            m["#{name}?"] = p
          else
            m[name] = proc { s.call[name] || value }
            m["#{name}?"] = proc { (s.call[name] || value).present? }
          end

          m.each { |k, v| define_singleton_method(k, v) }

          send(method_name)
        else
          super
        end
      end
    end
  end

  def self.patch
    PATCHES.each do |name|
      require File.expand_path("#{self.name.underscore}/patches/#{name.underscore}_patch", __dir__)

      target = name.constantize
      patch = "#{self.name}::Patches::#{name}Patch".constantize

      unless target.included_modules.include?(patch)
        target.send(:include, patch)
      end
    end
  end

  def self.hook
    require File.expand_path("#{self.name.underscore}/hook", __dir__)
  end

  def self.install
    patch
    hook
  end
end
