def caches_sql

# Dummy methods to make code work if cache_store is not set to :mem_cache_store, but all other code snippets are already in place. 

class << self
	alias_method :orig_find, :find
    alias_method :orig_find_every, :find_every
    def find(*args)
		args.delete(:nocache)
		orig_find(*args)
	end
	def reset_change_index()  	
	end
	def cache_delete(id)
	end
	private
	def find_every(*args)	
		args.delete(:nocache)
		orig_find_every(*args)
	end
end

if ActionController::Base.cache_store.to_s.index('MemCacheStore') 
class << self
    

#   make a backups of orignal find and find_every functions

    def find(*args)
		RAILS_DEFAULT_LOGGER.info "args.to_s"
    	if !args.delete(:nocache)
			if args[0].to_s.to_i && args[0].to_s.to_i > 0
	  			Rails.cache.fetch(gen_cache_id(args[0].to_s)) { orig_find(*args) }
			else
				Rails.cache.fetch(gen_cache_id(self.change_index + "/" + args.to_s)) { orig_find(*args) }
			end
		else
		orig_find(*args)
  		end
	end
  
    def change_index()    
		Rails.cache.fetch(gen_cache_id("Change-Index")) { Time.now.to_i.to_s }
	end
	
	def reset_cache_index()  	
		change_index()
		Rails.cache.write(gen_cache_id("Change-Index"), Time.now.to_i.to_s)
	end
	
    def gen_cache_id(key)
		str = Rails.root.to_s.split('/')
		ret = str[str.length - 1].to_s + '/' + self.to_s + '/' + key.gsub(/ /,'')
		#ret = ret.gsub(/\n/,'')
		if str.length < 250 
			return ret
		else 
			return Digest::MD5.hexdigest(ret)
		end
	end
	
	def cache_delete(id)
		Rails.cache.delete(gen_cache_id(id))
		reset_change_index
	end

	private
	
	# Override find_every method, so find_by_ methods are all cached as well
	def find_every(*args)	
  		if !args.delete(:nocache)
			Rails.cache.fetch(gen_cache_id(self.change_index + "/" + args.to_s)) { orig_find_every(*args) }
		else
			orig_find_every(*args)
		end
	end

end

else
	RAILS_DEFAULT_LOGGER.error "Caches_SQL will not work without cache_store set as :mem_cache_store!"
end
end