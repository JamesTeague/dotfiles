return {
  {
    "JamesTeague/pomodoro.nvim",
    depenencies = "MunifTanjim/nui.nvim",
    opts = {
      time_work = 25,
      time_break_short = 5,
      time_break_long = 20,
      timers_to_long_break = 4,
    },
    keys = {
      {
        "<leader>pt",
        "<CMD>:PomodoroStart<CR>",
        desc = "[P]omodoro Start Timer",
      },
      {
        "<leader>pp",
        "<CMD>:PomodoroStatus<CR>",
        desc = "[P]omodoro Status",
      },
      {
        "<leader>ps",
        "<CMD>:PomodoroStop<CR>",
        desc = "[P]omodoro Stop Timer",
      },
    },
  },
}
