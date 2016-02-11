#
CONFIG = {
  :token_key => "Rb-5qB56khXJYYWNlak_9cPOBwYCopIDh-u8RTzOCJYJJdURF7PSZc8XkMsEY2hXS8Sz",
  :qiniu => {
    ak: ENV["QINIU_AK"],
    sk: ENV["QINIU_SK"],
    basepath: ENV["QINIU_BASEPATH"]
  },
  :redis => {
      host: ENV["REDIS_HOST"],
      port: ENV["REDIS_PORT"].to_i,
      db: ENV["REDIS_DB"].to_i
  }
}
