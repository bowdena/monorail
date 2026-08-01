class PagesController < ApplicationController
  layout "main", except: %i[ login ]

  def home
  end

  def login
  end

  def settings
  end

  def changelog
  end

  def support
  end

  def patients
  end
end
