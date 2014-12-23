module Deployinator::Views
  class Index < Layout

    self.template_file = "#{File.dirname(__FILE__)}/../templates/index.mustache"

    # Public: Gets an array of stacks for use in templating the
    # index page.
    #
    # Retuns an array of non-pinned stacks!
    def get_other_stack_list
      Deployinator.get_stacks
    end
  end
end
