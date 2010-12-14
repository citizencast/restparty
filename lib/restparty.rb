class RestParty
  include HTTParty

  attr_reader :resource

  def self.resource_for(resource, options = {:methods => [:create, :index, :show, :update, :delete], :member => {}, :collection => {}})
    @resource = resource.to_s
    resource_methods = options[:methods]

    if !options[:only].blank?
      resource_methods = options[:only]
    elsif !options[:except].blank?
      resource_methods = [:create, :index, :show, :update, :delete]
      resource_methods.delete_if{|m| options[:except].include?(m)}
    end

    build_members(options[:member]) if options[:member]
    build_collections(options[:collection]) if options[:collection]
    build_create if resource_methods.include?(:create)
    build_get if resource_methods.include?(:index) || resource_methods.include?(:show)
    build_update if resource_methods.include?(:update)
    build_delete if resource_methods.include?(:delete)
  end

  private
    
    def build_delete
      class_eval %{
        def self.delete(id, options = {})
          delete('/#{resource}/'+id.to_s, :query => options)
        end
      }
    end
    
    def build_update
      class_eval %{
        def self.update(id, options = {})
          put('/#{resource}/'+id.to_s, :query => options, :headers => {'Content-Length' => '0'})
        end
      }
    end
    
    def build_get
      class_eval %{
        def self.find(id, options = {})
          response = ""
          if id.to_s == "all" and #{resource_methods.include?(:index)}
            response = get('/#{resource}', :query => options)
          elsif id.to_s =~ /^[-+]?[0-9]+$/ and #{resource_methods.include?(:show)}
            response = get('/#{resource}/'+id.to_s, :query => options)
          else
            raise "error"
          end
        end
      }
    end
    
    def build_create
      class_eval %{
        def self.create(options = {})
          post('/#{resource}', :query => options)
        end
      }
    end
    
    def build_collections(collections)
      collections.each_pair do |collection, method|
        raise 'error_http_method' unless valid_http_method?(method)
        class_eval %{
          def self.#{collection}(options = {})
            #{method}('/#{@resource}/#{collection}', :query => options)
          end
        }
      end
    end
    
    def build_members(members)
      members.each_pair do |member, method|
        raise 'error_method' unless valid_http_method?(method)
        class_eval %{
          def self.#{member}(id, options = {})
            #{method}('/#{@resource}/'+id.to_s+'/#{member}', :query => options)
          end
        }
      end
    end
  
    def self.valid_http_method?(method)
      ['post', 'get', 'put', 'delete', 'head'].include? method.to_s
    end
end