# PMD 静态代码分析实验报告

## 一、实验目的

使用 PMD（Programming Mistake Detector）工具对 Teedy 项目进行静态代码分析，识别代码中的潜在问题，并进行修复。

## 二、PMD 配置

### 2.1 配置信息

在项目的 `pom.xml` 中添加了 PMD Maven 插件：

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-pmd-plugin</artifactId>
    <version>3.21.0</version>
    <configuration>
        <linkXRef>false</linkXRef>
        <sourceEncoding>utf-8</sourceEncoding>
        <minimumTokens>100</minimumTokens>
        <targetJdk>11</targetJdk>
        <rulesets>
            <ruleset>/rulesets/java/basic.xml</ruleset>
            <ruleset>/rulesets/java/unusedcode.xml</ruleset>
            <ruleset>/rulesets/java/imports.xml</ruleset>
            <ruleset>/rulesets/java/design.xml</ruleset>
        </rulesets>
    </configuration>
</plugin>
```

### 2.2 运行命令

```bash
mvn pmd:pmd
```

## 三、检测结果统计

PMD 在 Teedy 项目中检测到以下类型的代码问题：

| 问题类型 | 数量 | 优先级 | 规则集 |
|---------|------|--------|--------|
| EmptyCatchBlock | 11 | 3 | Error Prone |
| UselessParentheses | 6 | 4 | Code Style |
| UnnecessaryImport | 5 | 4 | Code Style |
| UnnecessaryModifier | 4 | 4 | Code Style |
| CollapsibleIfStatements | 4 | 3 | Design |
| UnnecessaryFullyQualifiedName | 3 | 4 | Code Style |

**总计：33 个问题**

## 四、问题修复

选择了 3 种不同类型的问题进行修复：

### 4.1 修复类型一：UnnecessaryImport（不必要的导入）

**问题描述：** 代码中导入了未使用的类。

**位置：** `docs-core/src/main/java/com/sismics/util/jpa/EMF.java:17-18`

**修复前：**
```java
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
```

**修复后：**
```java
import java.util.Properties;
```

**修复理由：** 
- `HashMap` 和 `Map` 类在代码中没有被使用
- 移除未使用的导入可以提高代码可读性
- 减少不必要的依赖关系

---

### 4.2 修复类型二：EmptyCatchBlock（空的 catch 块）

**问题描述：** catch 块为空或只有注释，没有进行任何异常处理。

#### 修复示例 1

**位置：** `docs-core/src/main/java/com/sismics/util/ImageUtil.java:59-61`

**修复前：**
```java
try {
    imageOutputStream.close();
} catch (Exception inner) {
    // NOP
}
```

**修复后：**
```java
try {
    imageOutputStream.close();
} catch (Exception inner) {
    log.warn("Failed to close image output stream", inner);
}
```

#### 修复示例 2

**位置：** `docs-core/src/main/java/com/sismics/util/ImageUtil.java:133-135`

**修复前：**
```java
try {
    pixelRGBValue = image.getRGB(x, y);
    r = (pixelRGBValue >> 16) & 0xff;
    g = (pixelRGBValue >> 8) & 0xff;
    b = (pixelRGBValue) & 0xff;
    luminance = (r * 0.299) + (g * 0.587) + (b * 0.114);
} catch (Exception e) {
    // NOP
}
```

**修复后：**
```java
try {
    pixelRGBValue = image.getRGB(x, y);
    r = (pixelRGBValue >> 16) & 0xff;
    g = (pixelRGBValue >> 8) & 0xff;
    b = (pixelRGBValue) & 0xff;
    luminance = (r * 0.299) + (g * 0.587) + (b * 0.114);
} catch (Exception e) {
    log.warn("Failed to get RGB value at position ({}, {})", x, y, e);
}
```

**修复理由：**
- 空的 catch 块会吞掉异常，使得问题难以追踪和调试
- 添加日志记录可以帮助开发者了解程序运行时的异常情况
- 即使异常可以被忽略，也应该记录下来以便后续分析

**注意：** 修复过程中需要在 `ImageUtil.java` 类中添加 Logger 实例：
```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ImageUtil {
    private static final Logger log = LoggerFactory.getLogger(ImageUtil.class);
    // ...
}
```

---

### 4.3 修复类型三：CollapsibleIfStatements（可合并的 if 语句）

**问题描述：** 嵌套的 if 语句可以合并为一个条件表达式。

**位置：** `docs-core/src/main/java/com/sismics/docs/core/util/TransactionUtil.java:70-78`

**修复前：**
```java
// No error in the current request : commit the transaction
if (em.isOpen()) {
    if (em.getTransaction() != null && em.getTransaction().isActive()) {
        em.getTransaction().commit();
        
        try {
            em.close();
        } catch (Exception e) {
            log.error("Error closing entity manager", e);
        }
    }
}
```

**修复后：**
```java
// No error in the current request : commit the transaction
if (em.isOpen() && em.getTransaction() != null && em.getTransaction().isActive()) {
    em.getTransaction().commit();

    try {
        em.close();
    } catch (Exception e) {
        log.error("Error closing entity manager", e);
    }
}
```

**修复理由：**
- 减少代码嵌套层次，提高可读性
- 使用逻辑与运算符（&&）合并条件，代码更简洁
- 利用短路求值特性，保持原有的逻辑正确性

---

## 五、修复验证

修复完成后重新运行 PMD 检查：

```bash
mvn clean compile
mvn pmd:pmd
```

**结果：** BUILD SUCCESS

### 修复效果对比

| 问题类型 | 修复前 | 修复后 | 减少数量 |
|---------|--------|--------|----------|
| EmptyCatchBlock | 11 | 9 | 2 |
| UnnecessaryImport | 5 | 3 | 2 |
| CollapsibleIfStatements | 4 | 3 | 1 |
| UselessParentheses | 6 | 6 | 0 |
| UnnecessaryModifier | 4 | 4 | 0 |
| UnnecessaryFullyQualifiedName | 3 | 3 | 0 |
| **总计** | **33** | **28** | **5** |

成功修复了 5 个代码问题，问题总数从 33 个减少到 28 个。

## 六、实验总结

### 6.1 PMD 的优势

1. **自动化检测**：能够快速扫描大型代码库，发现潜在问题
2. **规则丰富**：提供多种规则集，覆盖代码风格、设计、错误倾向等多个方面
3. **易于集成**：可以轻松集成到 Maven/Gradle 构建流程中
4. **可定制化**：支持自定义规则，满足特定项目需求

### 6.2 常见问题类型

通过本次分析，发现 Teedy 项目中最常见的问题包括：

1. **空的异常处理块**：这是最严重的问题，可能导致错误被静默忽略
2. **代码风格问题**：如无用的括号、不必要的导入等
3. **设计问题**：如可合并的 if 语句，影响代码可读性

### 6.3 最佳实践建议

1. **异常处理**：永远不要使用空的 catch 块，至少应该记录日志
2. **代码整洁**：定期清理未使用的导入和变量
3. **简化逻辑**：合并嵌套的条件语句，减少代码复杂度
4. **持续集成**：将 PMD 检查集成到 CI/CD 流程中，在代码提交前自动检测问题

### 6.4 改进方向

1. 可以创建自定义 PMD 规则，针对项目特定的编码规范
2. 设置更严格的规则集，提高代码质量标准
3. 配置 PMD 在构建失败时阻止部署，强制修复问题

## 七、附录

### 7.1 PMD 报告位置

- docs-core: `docs-core/target/pmd.xml`
- docs-web: `docs-web/target/pmd.xml`
- docs-web-common: `docs-web-common/target/pmd.xml`

### 7.2 HTML 报告

可以通过以下命令生成 HTML 格式的报告：

```bash
mvn site
```

报告将生成在 `target/site/pmd.html`

---

**实验完成时间：** 2026-04-21  
**实验工具版本：** Maven PMD Plugin 3.21.0
