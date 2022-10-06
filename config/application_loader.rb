# frozen_string_literal: true

module ApplicationLoader
  ROOT_PATH = File.expand_path('..', __dir__).freeze

  extend self

  def load_app!
    init_configurable
    init_db

    require_app
    require_initializers
  end

  private

  def init_configurable
    require_file 'config/initializers/configurable'
  end

  def init_db
    require_file 'config/initializers/db'
  end

  def require_app
    require_file 'config/application'
    require_file 'app/services/basic_service'
    require_dir 'app'
  end

  def require_initializers
    require_dir 'config/initializers'
  end

  def require_file(path)
    require File.join(ROOT_PATH, path)
  end

  def require_dir(path)
    path = File.join(ROOT_PATH, path)
    Dir["#{path}/**/*.rb"].each { |file| require file}
  end
end
