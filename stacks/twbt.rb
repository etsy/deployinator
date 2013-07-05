module Deployinator
  module Stacks
    module Twbt
      def uat_version
         %x{ssh deploy@pitch160.anchor.net.au cat /home/deploy/apps/uat_12wbt/current/REVISION | cut -c1-7}
      end
      def prod_version
         %x{ssh deploy@martingale.anchor.net.au cat /home/deploy/apps/12wbt/current/REVISION | cut -c1-7}
      end
      def current_uat_build
        uat_version
      end
      def current_prod_build
        prod_version
      end
      def next_build
       %x{git ls-remote git@github.com:red-ant/12wbt HEAD | cut -c1-7}.chomp
      end
      def prod_deploy(options={})
        run_cmd %Q(cap deploy -S stage=production)
      end
      def uat_deploy(options={})
        run_cmd %Q(cap deploy -S stage=uat)
        #        run_cmd %Q{source ~/.rvm/scripts/rvm; cd /home/jago/work/12wbt;rvm use @deploy;cap deploy -S stage=uat}
      end
      def twbt_environments
        [
          {
            :name => "uat",
            :method => "uat_deploy",
            :current_version => uat_version,
            :current_build => current_uat_build,
            :next_build => next_build
          },
          {
            :name => "production",
            :method => "prod_deploy",
            :current_version => prod_version,
            :current_build => current_prod_build,
            :next_build => next_build
          }
        ]
      end
      def twbt_production_version
        # %x{curl http://my-app.com/version.txt}
        "cf44aab-20110729-230910-UTC"
      end
      def twbt_head_build
        # the build version you're about to push
        # %x{git ls-remote #{your_git_repo_url} HEAD | cut -c1-7}.chomp
        "11666e3"
      end

      def twbt_production(options={})
        log_and_stream "Fill in the twbt_production method in stacks/twbt.rb!<br>"

        # log the deploy
        log_and_shout :old_build => environments[0][:current_build].call, :build => environments[0][:next_build].call
      end
    end
  end
end
