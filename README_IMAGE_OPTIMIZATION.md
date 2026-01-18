# 图片优化工具使用指南

本目录包含用于优化博客图片的脚本工具集。

## 📁 脚本说明

### 主要脚本

1. **`optimize-images.sh`** - 主优化脚本
   - 将PNG文件转换为WebP格式（质量85）
   - 优化大尺寸JPG文件（自动调整超过2000px的图片）
   - 自动创建备份目录

2. **`update-markdown-refs.sh`** - 更新Markdown引用
   - 自动将markdown文件中的`.png`引用更新为`.webp`

3. **`cleanup-original-pngs.sh`** - 清理原始PNG
   - 删除已成功转换为WebP的原始PNG文件
   - 保留WebP更大的PNG文件

4. **`cleanup-unused-pngs.sh`** - 清理未使用的PNG
   - 删除未被任何markdown文件引用的PNG文件

5. **`verify-optimization.sh`** - 验证优化结果
   - 检查WebP文件是否存在
   - 验证markdown中无PNG引用
   - 检查文件大小

6. **`prepare-commit.sh`** - 准备Git提交
   - 自动添加所有优化相关的文件到git
   - 生成提交信息

## 🚀 使用流程

### 完整优化流程

```bash
# 1. 运行优化脚本
./optimize-images.sh

# 2. 更新markdown引用
./update-markdown-refs.sh

# 3. 清理原始PNG文件
./cleanup-original-pngs.sh

# 4. 清理未使用的PNG文件（可选）
./cleanup-unused-pngs.sh

# 5. 验证优化结果
./verify-optimization.sh

# 6. 准备Git提交
./prepare-commit.sh

# 7. 提交更改
git commit -m "Optimize images: Convert PNG to WebP, optimize JPG files"
```

### 单独使用

如果只需要转换新图片：

```bash
# 只转换PNG到WebP
./optimize-images.sh

# 只更新markdown引用
./update-markdown-refs.sh
```

## 📊 优化效果

- **空间节省**: 通常可节省60-70%的存储空间
- **加载速度**: WebP格式加载更快
- **浏览器支持**: 所有现代浏览器都支持WebP

## ⚙️ 配置

### WebP质量设置

编辑 `optimize-images.sh`，修改质量参数：

```bash
# 当前设置：质量85（推荐）
cwebp -q 85 "$png_file" -o "$webp_file"

# 更高质量（更大文件）：质量90-95
# 更低质量（更小文件）：质量75-80
```

### JPG优化阈值

编辑 `optimize-images.sh`，修改优化阈值：

```bash
# 当前设置：只优化大于500KB的文件
if [ "$size_before" -lt 512000 ]; then
    # 跳过小文件
fi

# 调整尺寸阈值（当前：2000px）
if [ "$width" -gt 2000 ]; then
    # 调整大图
fi
```

## 🔍 验证

运行验证脚本检查优化结果：

```bash
./verify-optimization.sh
```

验证内容包括：
- ✓ WebP文件存在性检查
- ✓ Markdown中无PNG引用
- ✓ 文件大小检查
- ✓ 备份目录检查

## 📝 注意事项

1. **备份**: 优化脚本会自动创建备份目录 `content/posts/images-backup/`
2. **不可逆**: PNG转WebP是不可逆的，请确保备份完整
3. **测试**: 优化后务必测试博客确保图片正常显示
4. **Git**: 使用 `prepare-commit.sh` 准备提交，避免遗漏文件

## 🗑️ 清理备份

验证一切正常后，可以删除备份：

```bash
rm -rf content/posts/images-backup
```

备份目录已添加到 `.gitignore`，不会被提交到git。

## 📚 相关文档

- `IMAGE_OPTIMIZATION.md` - 详细的优化说明
- `OPTIMIZATION_COMPLETE.md` - 优化完成报告
- `docs/ai-publishing.md` - AI发布规范（包含图片路径说明）

## 🐛 故障排除

### WebP转换失败

检查是否安装了 `cwebp`：

```bash
which cwebp
# 如果未安装：brew install webp
```

### JPG优化失败

检查是否安装了 `sips`（macOS自带）：

```bash
which sips
# macOS系统自带，无需安装
```

### Markdown引用未更新

手动检查并更新：

```bash
# 查找PNG引用
grep -r "\.png" content/posts/*.md

# 手动替换
sed -i '' 's/\.png/.webp/g' content/posts/*.md
```

## 📞 支持

如有问题，请检查：
1. 脚本执行权限：`chmod +x *.sh`
2. 工具是否安装：`which cwebp sips`
3. 文件路径是否正确
