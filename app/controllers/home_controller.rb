class HomeController < ApplicationController
  def index
    @lawsuits = Lawsuit.all
  end
end