---
title:  "如何阅读 TiDB 的源代码（二）"
date: 2020-07-12T12:09:00+08:00
---

接[上篇](/posts/tidb1)，我们知道了怎么去搭建读代码的环境，从哪里入口来读代码。本篇开始会根据一些常见地查看代码需求，介绍它们的查看方法。

## 如何查看某个语法的支持程度

常见的有两种方法，

1. 通过 parser repo 来查
1. 直接在 TiDB repo 里查看

这两种方法都需要[上篇的环境搭建](/posts/tidb1#环境搭建)部分。还没尝试的可以去尝试一下。

### 准备工作

1. 安装 GoYacc Support

    ![goyacc](/posts/images/20200712124300.png)
    
    GoYacc Support 插件是我司同学的作品，JetBrains 正式接受的第三方插件，属于上得了厅堂的作品。
    其包含了语法高亮和 Intelligent，非常赞！
    
1. 下载 [parser repo](https://github.com/pingcap/parser)

    如果从 parser 直接看语法，需要手动下载；如果从 TiDB 里跳转，IDEA 会自动下载代码，反而不需要额外操作。

### 通过 parser repo 来查

用 IDEA 打开 parser，切换到自己需要的分支，找到 parser.y 文件。不过，更推荐的是从 TiDB 里查看。

### 通过 TiDB repo 来查

1. 用 IDEA 打开 TiDB 工程，切换到需要的分支

    ![co](/posts/images/20200712183012.png)
    
1. 找到 parser.y 文件，注意搜索的时候要选最大的搜索的 scope

    ![parser.y](/posts/images/20200712183658.png)

    也可以从文件列表里找到，
    
    ![parser.y2](/posts/images/20200712184101.png)
    
    ![parser.y3](/posts/images/20200712184157.png)
    
下面我们以查 `SHOW ENGINES` 这个 SQL 来举例。

整个语句解析的入口是 [Start](https://github.com/pingcap/parser/blob/f56688124d8bbba98ca103dbcc667d0e3b9bef30/parser.y#L1309-L1308)
它下面是 StatementList，然后是，Statement。在 Statement 的大列表下，可以找到 ShowStmt

![parser.y4](/posts/images/20200712184841.png)

但是 ShowStmt 其实非常复杂，另一种方式是直接在 parser.y 里搜索 `ShowEngines`，因为其命名都是遵循 Golang 的规则，驼峰式+暴漏对外要首字母大写。
当然，如果熟悉代码的话会知道，`ShowEngines` 其实在 `ShowTargetFilterable` 里。其第一个分支就是 `ShowEngines`

![parser.y5](/posts/images/20200712185533.png)

**那对 `SHOW ENGINES` 的支持是怎样的呢？**

可以看一下对 `ast.ShowEngines` 是怎么处理的。这里就不能继续跳转了，需要复制后搜索。

![parser.y6](/posts/images/20200712190242.png)

这里只需要看 TiDB 下是怎么处理的，test 文件里的也可以直接跳过。

![parser.y7](/posts/images/20200712190752.png)

这里一个是实际的实现，

![parser.y7](/posts/images/20200712190839.png)

另一个是 build schema，也就是表头，可以不用管，

![parser.y7](/posts/images/20200712190956.png)

进了 `fetchShowEngines` 就能看到了，其实它的具体实现很简单，就是执行一个内部 SQL，读了一下系统表。

![parser.y7](/posts/images/20200712191054.png)

查看 `SHOW ENGINES` 就到此结束了。可以看到它是完全支持的。

**哪些语句是只有语法支持的呢？**

以创建临时表的语法为例，找到它在 parser.y 里的位置

![parser.y8](/posts/images/20200712191711.png)

它是一个选项

![parser.y9](/posts/images/20200712191843.png)

其实可以看到，如果指定了临时表选项的话，它只会返回一个 true，然后附加一个 warning，说明，这个表还是按照普通表来处理的。
parser 里以前还有很多只是返回但什么都不干的操作，连 warning 都没有，不过这些现在比较少了。

#### 通过 TiDB repo 查询的好处

可以看到，通过 TiDB repo 来看，可以通过 IDEA 找对应的 parser 的详细的 hash。如果，通过 parser 来直接看
需要先从 TiDB 的 go.mod 里查一下 parser 的 hash，然后，在 parser 里 check out 到对应的 hash，
如果要查具体实现，需要再回到 TiDB 里，这样查来查去不如在一个工程下看方便，唯一的好处是，可以方便地 blame
提交历史。

## 默认配置查看及修改

默认配置在 TiDB 中很容易查看，具体就是 [defaultConf](https://github.com/pingcap/tidb/blob/72f6a0405837b92e40de979a4f3134d9aa19a5b3/config/config.go#L547)
这个变量。在这里列出的就是真正的默认配置。

![conf1](/posts/images/20200713172228.png)

以第一个 Host 配置为例，其有向 toml 和 json 文件的映射。

![conf2](/posts/images/20200713172535.png)

也就是比如，到了 toml 文件里应该怎么写。后面的 `DefHost` 是具体的默认值。

![conf3](/posts/images/20200713180137.png)

这里需要注意的是，配置是有层级关系的。以 log 的相关配置为例，在配置文件中是

![conf4](/posts/images/20200715164756.png)

在代码中则表示为，

![conf5](/posts/images/20200715164930.png)

这样就表示成了在 log 配置下有一个叫 level 的配置。

如果继续增加层级怎么办？比如最复杂的 CopCache 的配置，它是在 tikv-client 下又增加了一个层级 copr-cache，

![conf6](/posts/images/20200715165243.png)

由于 toml 文件不支持多级嵌套，因此，这就造就了 TiDB 的最复杂的一个配置写法，

![conf6](/posts/images/20200715165456.png)

想让上文说的通过 IDEA 启动的 TiDB 使用非默认配置的方法，最简单的也是改这个 defaultConf。

## 总结

至此，可以看到，查看一个语句是否支持，并且是仅仅语法支持还是有具体实现，都可以通过上述方法来实现。并且知道了如何查看并修改默认配置的方法，大家可以自己进行一些验证。
下一篇，我计划介绍下 TiDB 的系统变量。

