# -*- coding: utf-8 -*-
require 'optparse'
require 'codestock/cdstk/cli_cdstksub'
require 'codestock/cdstk/cdstk'
require 'codestock/common/dbdir.rb'
require 'codestock/cdweb/cli_cdweb'
include CodeStock

module CodeStock
  class CLI_Cdstk
    def self.execute(stdout, arguments=[])
      opt = OptionParser.new <<EOF
#{File.basename($0)} COMMAND [ARGS]

The most commonly used #{File.basename($0)} are:
  init        Init db.
  add         Add packages.
  update      Update packages.
  web         Run web-app.
  remove      Remove packages.
  list        List packages. 
  pwd         Disp current db.
  cleanup     Cleanup garbage records.
  rebuild     Rebuild db.
  dump        Dump records.
EOF

      subopt = Hash.new
      suboptions = Hash.new
      
      subopt['init'], suboptions['init'] = CLI_Cdstksub.setup_init
      subopt['add'] = CLI_Cdstksub.setup_add
      subopt['update'] = OptionParser.new("#{File.basename($0)} update package1 [package2 ...]")
      subopt['remove'], suboptions['remove'] = CLI_Cdstksub.setup_remove
      subopt['list'], suboptions['list'] = CLI_Cdstksub.setup_list
      subopt['pwd'], suboptions['pwd'] = CLI_Cdstksub.setup_pwd
      subopt['cleanup'], suboptions['cleanup'] = CLI_Cdstksub.setup_cleanup
      subopt['rebuild'] = OptionParser.new("#{File.basename($0)} rebuild")
      subopt['dump'] = OptionParser.new("#{File.basename($0)} dump")
      subopt['web'], suboptions['web'] = CLI_Cdstksub.setup_web

      opt.order!(arguments)
      subcommand = arguments.shift

      if (subopt[subcommand])
        subopt[subcommand].parse!(arguments) unless arguments.empty?
        init_default = suboptions['init'][:init_default]

        db_dir = select_dbdir(subcommand, init_default)
        obj = Cdstk.new(stdout, db_dir)

        case subcommand
        when 'init'
          FileUtils.mkdir_p db_dir if (init_default)
          obj.init 
        when 'update'
          obj.update(arguments)
        when 'add'
          obj.add(arguments)
        when 'remove'
          obj.remove(arguments, suboptions[subcommand])
        when 'list'
          obj.list(arguments, suboptions[subcommand])
        when 'pwd'
          obj.pwd(suboptions[subcommand])
        when 'cleanup'
          obj.cleanup(suboptions[subcommand])
        when 'rebuild'
          obj.rebuild
        when 'dump'
          obj.dump
        when 'web'
          CodeStock::CLI_Cdweb.execute_with_options(stdout, suboptions[subcommand])
        end
      else
        if subcommand
          $stderr.puts "#{File.basename($0)}: '#{subcommand}' is not a #{File.basename($0)} command. See '#{File.basename($0)} --help'"
        else
          stdout.puts opt.help
        end
      end
    end

    private

    def self.select_dbdir(subcommand, init_default)
      if (subcommand == 'init')
        if (init_default)
          db_default_dir
        else
          '.'
        end
      else
        if (dbdir?('.') || !dbdir?(db_default_dir))
          '.'
        else
          db_default_dir
        end
      end
    end
 
  end
end
