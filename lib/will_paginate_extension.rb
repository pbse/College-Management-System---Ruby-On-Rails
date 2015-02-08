module WillPaginateExtension
  module Array
    def model_paginate(options = {})
      raise ArgumentError, "parameter hash expected (got #{options.inspect})" unless Hash === options
      total = 0
      t_array = []

      self.each do |model|
        case model.class.name
        when "Symbol"
          model_const = model.to_s.camelize.constantize
          t_array << model_const.count
        when "Hash"
          model_const = model.keys.first.to_s.camelize.constantize
          res = model_const.send :with_scope, :find =>model.values.first.extract_ar_options do
            model.values.first[:search_options].nil?? (model_const.all(:select=>model.values.first[:select],:group=>model.values.first[:group],:having=>model.values.first[:having])).count : (model_const.search(model.values.first[:search_options])).count
          end
          t_array << res
        else
          raise "Array contents should be model name (symbols) or model name and scope (hash of symbol)"
        end
      end

      total = t_array.sum

      WillPaginate::Collection.create(options[:page]||1,options[:per_page],total) do |pager|
        count = (pager.current_page - 1) * pager.per_page
        count_limit = count + pager.per_page
        return [] if count > total
        model_var = 0
        model_index = 0
        rel_offset = pager.offset
        t_array.each_with_index do |e,i|
          model_var += e;
          if model_var >= count
            model_index = i
            rel_offset = (count - (model_var-e))
            break
          end
        end

        while((count_limit > count) and (t_array.length) !=  (model_index))
          current_model = self[model_index]
          case current_model.class.name
          when "Symbol"
            current_model_const = current_model.to_s.camelize.constantize
            pager << (current_model_const.send :all, :limit=>(pager.per_page - pager.length),:offset=>rel_offset)
          when "Hash"
            current_model_const = current_model.keys.first.to_s.camelize.constantize
            res = current_model_const.send :with_scope, :find => current_model.values.first.extract_ar_options do
              ((current_model_const.scoped(:limit=>(pager.per_page - pager.length),:offset=>rel_offset)).send :search,current_model.values.first[:search_options]).all
            end
            pager << res
          else
            raise "Array contents should be model name (symbols) or model name and options (hash of symbol)"
          end
          pager.flatten!
          count += pager.count
          if pager.length < pager.per_page
            model_index += 1
            rel_offset = 0
          end
        end

      end

    end
  end
  module Hash
    def extract_ar_options
      valid_opts = [:conditions,:joins,:order,:include,:select,:group,:having]
      result = {}
      self.each{|k,v| result[k]=v if valid_opts.include? k}
      result
    end
  end
end
