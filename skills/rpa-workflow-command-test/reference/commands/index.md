# Web UI 自动化指令目录

共 **96** 条 UI 指令，从 [官方文档](https://document.waimai.st.sankuai.com/) 提取。

每条 reference 含：**指令标识**、**输入/输出参数**、**必填项**、**XML 示例**（如有）、**注意事项**（如有）。

配置 bots 指令时，Read 对应 `reference/commands/<slug>.md`，不要全量加载。

**插入指令**：在右侧「指令」Tab 搜索框「请输入」set_value **中文平台指令名**（如下表第一列）→ **双击**「网页自动化」分组下匹配的 `xxx (web)` 结果。详见 `reference/platform-ops.md` §2.3。

## 网页指令

| 平台指令名 | 指令标识 | 必填输入参数 | reference | 官方文档 |
|-----------|---------|-------------|-----------|---------|
| 上传文件 | `UploadFileFromS3` | 元素选择器, 文件S3路径 | [uploadfilefroms3.md](uploadfilefroms3.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/uploadfilefroms3/ |
| 关闭指定URL网页 | `ClosePageByUrl` | URL | [closepagebyurl.md](closepagebyurl.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/closepagebyurl/ |
| 关闭指定标题网页 | `ClosePageByTitle` | 标题 | [closepagebytitle.md](closepagebytitle.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/closepagebytitle/ |
| 关闭指定索引网页 | `ClosePageIndex` | 索引 | [closepageindex.md](closepageindex.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/closepageindex/ |
| 关闭浏览器 | `CloseBrowser` | - | [closebrowser.md](closebrowser.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/closebrowser/ |
| 切换到指定URL网页 | `SwitchToWindowUrl` | URL | [switchtowindowurl.md](switchtowindowurl.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/switchtowindowurl/ |
| 切换到指定标题网页 | `SwitchToWindowTitle` | 标题 | [switchtowindowtitle.md](switchtowindowtitle.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/switchtowindowtitle/ |
| 切换到指定索引网页 | `SwitchToWindowIndex` | 索引 | [switchtowindowindex.md](switchtowindowindex.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/switchtowindowindex/ |
| 删除所有Cookie | `DeleteAllCookies` | - | [deleteallcookies.md](deleteallcookies.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/deleteallcookies/ |
| 刷新网页 | `ReloadPage` | - | [reloadpage.md](reloadpage.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/reloadpage/ |
| 导航到URL | `NavigateToUrl` | 导航到的网址 | [navigatetourl.md](navigatetourl.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/navigatetourl/ |
| 截图 | `TakeScreenshot` | - | [takescreenshot.md](takescreenshot.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/takescreenshot/ |
| 打开网页 | `OpenUrl` | 网址 | [openurl.md](openurl.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/openurl/ |
| 拖拽到元素 | `DragAndDropByObject` | 源元素选择器, 目标元素选择器 | [draganddropbyobject.md](draganddropbyobject.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/draganddropbyobject/ |
| 模拟快捷键 | `SendKeys` | 元素选择器, 快捷键组合 | [sendkeys.md](sendkeys.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/sendkeys/ |
| 按偏移量滚动 | `ScrollToPosition` | 起点横坐标, 起点纵坐标 | [scrolltoposition.md](scrolltoposition.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/scrolltoposition/ |
| 滚动到元素 | `ScrollToElement` | 元素选择器 | [scrolltoelement.md](scrolltoelement.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/scrolltoelement/ |
| 点击元素（推荐） | `ClickElementMixed` | 元素选择器 | [clickelementmixed.md](clickelementmixed.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/clickelementmixed/ |
| 等待元素不存在 | `WaitForElementNotPresent` | 元素选择器 | [waitforelementnotpresent.md](waitforelementnotpresent.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/waitforelementnotpresent/ |
| 等待元素具有属性 | `WaitForElementHasAttribute` | 元素选择器, 属性名称 | [waitforelementhasattribute.md](waitforelementhasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/waitforelementhasattribute/ |
| 等待元素存在 | `WaitForElementPresent` | 元素选择器 | [waitforelementpresent.md](waitforelementpresent.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/waitforelementpresent/ |
| 等待元素没有属性 | `WaitForElementNotHasAttribute` | 元素选择器, 属性名称 | [waitforelementnothasattribute.md](waitforelementnothasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/waitforelementnothasattribute/ |
| 等待页面加载 | `WaitPageState` | 加载状态 | [waitpagestate.md](waitpagestate.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/waitpagestate/ |
| 网页前进 | `ForwardPage` | - | [forwardpage.md](forwardpage.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/forwardpage/ |
| 网页后退 | `BackPage` | - | [backpage.md](backpage.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/backpage/ |
| 获取下拉框选中选项数量 | `GetNumberOfSelectedOption` | 元素选择器 | [getnumberofselectedoption.md](getnumberofselectedoption.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/getnumberofselectedoption/ |
| 获取下拉框选项数量 | `GetNumberOfTotalOption` | 元素选择器 | [getnumberoftotaloption.md](getnumberoftotaloption.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/getnumberoftotaloption/ |
| 获取元素属性 | `GetElementAttribute` | 元素选择器, 属性名称 | [getelementattribute.md](getelementattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/getelementattribute/ |
| 获取当前网页URL | `GetUrl` | 将结果保存至 | [geturl.md](geturl.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/geturl/ |
| 获取当前网页标题 | `GetWindowTitle` | 将结果保存至 | [getwindowtitle.md](getwindowtitle.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/getwindowtitle/ |
| 获取当前网页索引 | `GetWindowIndex` | 将结果保存至 | [getwindowindex.md](getwindowindex.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/getwindowindex/ |
| 获取所有Cookie信息 | `GetSelectAllCookie` | URL | [getselectallcookie.md](getselectallcookie.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/getselectallcookie/ |
| 获取指定Cookie信息 | `GetSelectSpecifyCookie` | URL, Cookie名称 | [getselectspecifycookie.md](getselectspecifycookie.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/getselectspecifycookie/ |
| 获取文本 | `GetText` | 元素选择器 | [gettext.md](gettext.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/gettext/ |
| 设置Cookie信息 | `SetCookie` | 设置方式, Name | [setcookie.md](setcookie.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/setcookie/ |
| 输入文本 | `FillText` | 元素选择器, 待填充文本 | [filltext.md](filltext.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/filltext/ |
| 验证元素不可见 | `VerifyElementNotVisible` | 元素选择器 | [verifyelementnotvisible.md](verifyelementnotvisible.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementnotvisible/ |
| 验证元素不存在 | `VerifyElementNotPresent` | 元素选择器 | [verifyelementnotpresent.md](verifyelementnotpresent.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementnotpresent/ |
| 验证元素具有属性 | `VerifyElementHasAttribute` | 元素选择器, 属性名称 | [verifyelementhasattribute.md](verifyelementhasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementhasattribute/ |
| 验证元素可见 | `VerifyElementVisible` | 元素选择器 | [verifyelementvisible.md](verifyelementvisible.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementvisible/ |
| 验证元素存在 | `VerifyElementPresent` | 元素选择器 | [verifyelementpresent.md](verifyelementpresent.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementpresent/ |
| 验证元素属性值 | `VerifyElementAttributeValue` | 元素选择器, 属性名称, 属性值 | [verifyelementattributevalue.md](verifyelementattributevalue.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementattributevalue/ |
| 验证元素没有属性 | `VerifyElementNotHasAttribute` | 元素选择器, 属性名称 | [verifyelementnothasattribute.md](verifyelementnothasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyelementnothasattribute/ |
| 验证当前页面所有可访问链接 | `VerifyPageAllLinksAccess` | - | [verifypagealllinksaccess.md](verifypagealllinksaccess.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifypagealllinksaccess/ |
| 鼠标悬停 | `MouseOver` | 元素选择器 | [mouseover.md](mouseover.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mouseover/ |
| 鼠标悬停偏移 | `MouseOverOffset` | 元素选择器, 偏移X, 偏移Y | [mouseoveroffset.md](mouseoveroffset.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mouseoveroffset/ |

## 移动端指令

| 平台指令名 | 指令标识 | 必填输入参数 | reference | 官方文档 |
|-----------|---------|-------------|-----------|---------|
| 关闭应用 | `MobileCloseApplication` | appPackage | [mobilecloseapplication.md](mobilecloseapplication.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilecloseapplication/ |
| 关闭通知 | `MobileCloseNotification` | - | [mobileclosenotification.md](mobileclosenotification.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileclosenotification/ |
| 卸载应用 | `UnInstallApplication` | 应用包名 | [uninstallapplication.md](uninstallapplication.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/uninstallapplication/ |
| 双击坐标 | `MobileDoubleTapAtPosition` | x坐标, y坐标 | [mobiledoubletapatposition.md](mobiledoubletapatposition.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobiledoubletapatposition/ |
| 安卓返回键 | `MobilePressBack` | - | [mobilepressback.md](mobilepressback.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilepressback/ |
| 安装应用 | `InstallApplication` | appPath | [installapplication.md](installapplication.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/installapplication/ |
| 手机截屏 | `MobileTakeScreenshot` | 将结果保存至 | [mobiletakescreenshot.md](mobiletakescreenshot.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobiletakescreenshot/ |
| 打开应用 | `MobileOpenApplication` | appPackage | [mobileopenapplication.md](mobileopenapplication.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileopenapplication/ |
| 打开通知 | `MobileOpenNotification` | - | [mobileopennotification.md](mobileopennotification.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileopennotification/ |
| 执行安卓adb shell命令 | `ExecuteMobileCommand` | 命令 | [executemobilecommand.md](executemobilecommand.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/executemobilecommand/ |
| 拖拽到元素 | `MobileDragAndDrop` | 源元素选择器, 目标元素选择器 | [mobiledraganddrop.md](mobiledraganddrop.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobiledraganddrop/ |
| 根据屏幕比例滑动 | `MobileSwipeByProportion` | startX, startY, endX, endY, slideSpeed | [mobileswipebyproportion.md](mobileswipebyproportion.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileswipebyproportion/ |
| 根据方向滑动屏幕 | `MobileSwipeByDirection` | slideDirection | [mobileswipebydirection.md](mobileswipebydirection.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileswipebydirection/ |
| 模拟键盘输入 | `MobileSendKeysWithoutEle` | 输入内容 | [mobilesendkeyswithoutele.md](mobilesendkeyswithoutele.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilesendkeyswithoutele/ |
| 清除文本 | `MobileClearText` | 元素选择器 | [mobilecleartext.md](mobilecleartext.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilecleartext/ |
| 点击 | `MobileTap` | selector | [mobiletap.md](mobiletap.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobiletap/ |
| 点击Home键 | `MobilePressHome` | - | [mobilepresshome.md](mobilepresshome.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilepresshome/ |
| 点击图像 | `MobileTapOnImage` | imageFilePath | [mobiletaponimage.md](mobiletaponimage.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobiletaponimage/ |
| 点击坐标 | `MobileTapAtPosition` | x, y | [mobiletapatposition.md](mobiletapatposition.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobiletapatposition/ |
| 等待元素不存在 | `MobileWaitForElementNotPresent` | 元素选择器, 超时时间 | [mobilewaitforelementnotpresent.md](mobilewaitforelementnotpresent.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilewaitforelementnotpresent/ |
| 等待元素具有属性 | `MobileWaitForElementHasAttribute` | 元素选择器, 属性名称 | [mobilewaitforelementhasattribute.md](mobilewaitforelementhasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilewaitforelementhasattribute/ |
| 等待元素存在 | `MobileWaitForElementPresent` | 元素选择器, 超时时间 | [mobilewaitforelementpresent.md](mobilewaitforelementpresent.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilewaitforelementpresent/ |
| 等待元素没有属性 | `MobileWaitForElementNotHasAttribute` | 元素选择器, 属性名称 | [mobilewaitforelementnothasattribute.md](mobilewaitforelementnothasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilewaitforelementnothasattribute/ |
| 获取元素属性 | `MobileGetAttribute` | 元素选择器, 元素属性名 | [mobilegetattribute.md](mobilegetattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilegetattribute/ |
| 获取手机屏幕宽度 | `MobileGetDeviceWidth` | - | [mobilegetdevicewidth.md](mobilegetdevicewidth.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilegetdevicewidth/ |
| 获取手机屏幕高度 | `MobileGetDeviceHeight` | - | [mobilegetdeviceheight.md](mobilegetdeviceheight.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilegetdeviceheight/ |
| 跳转到scheme页面 | `NavigateToScheme` | app中的url链接 | [navigatetoscheme.md](navigatetoscheme.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/navigatetoscheme/ |
| 输入文本 | `MobileSendKeys` | selector, keyword | [mobilesendkeys.md](mobilesendkeys.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilesendkeys/ |
| 长按坐标 | `MobileLongPress` | x坐标, y坐标 | [mobilelongpress.md](mobilelongpress.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilelongpress/ |
| 隐藏安卓键盘 | `MobileHideKeyboard` | - | [mobilehidekeyboard.md](mobilehidekeyboard.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobilehidekeyboard/ |
| 验证元素不存在 | `MobileVerifyElementNotExist` | 元素选择器 | [mobileverifyelementnotexist.md](mobileverifyelementnotexist.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementnotexist/ |
| 验证元素具有属性 | `MobileVerifyElementHasAttribute` | 元素选择器, 属性名称 | [mobileverifyelementhasattribute.md](mobileverifyelementhasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementhasattribute/ |
| 验证元素存在 | `MobileVerifyElementExist` | 元素选择器 | [mobileverifyelementexist.md](mobileverifyelementexist.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementexist/ |
| 验证元素属性值 | `MobileVerifyElementAttributeValue` | 元素选择器, 属性名称, 属性值 | [mobileverifyelementattributevalue.md](mobileverifyelementattributevalue.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementattributevalue/ |
| 验证元素没有属性 | `MobileVerifyElementNotHasAttribute` | 元素选择器, 元素属性名称 | [mobileverifyelementnothasattribute.md](mobileverifyelementnothasattribute.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyelementnothasattribute/ |
| 验证图片存在 | `MobileVerifyImagePresent` | 图片S3地址 | [mobileverifyimagepresent.md](mobileverifyimagepresent.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyimagepresent/ |
| 验证图片相似度>90% | `MobileVerifyImageSimilarity` | 测试文件的S3地址, 目标文件的S3地址 | [mobileverifyimagesimilarity.md](mobileverifyimagesimilarity.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/mobileverifyimagesimilarity/ |

## 其他指令

| 平台指令名 | 指令标识 | 必填输入参数 | reference | 官方文档 |
|-----------|---------|-------------|-----------|---------|
| 字符串拼接 | `Concatenate` | 字符串 | [concatenate.md](concatenate.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/concatenate/ |
| 延迟 | `Delay` | 延迟时间 | [delay.md](delay.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/delay/ |
| 打印日志 | `Comment` | 日志内容 | [comment.md](comment.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/comment/ |
| 断言 | `Assert` | 断言失败条件 | [assert.md](assert.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/assert/ |
| 验证不相等 | `VerifyNotEqual` | 实际值, 期望值 | [verifynotequal.md](verifynotequal.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifynotequal/ |
| 验证大于 | `VerifyGreaterThan` | 实际值, 期望值 | [verifygreaterthan.md](verifygreaterthan.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifygreaterthan/ |
| 验证大于等于 | `VerifyGreaterThanOrEqual` | 实际值, 期望值 | [verifygreaterthanorequal.md](verifygreaterthanorequal.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifygreaterthanorequal/ |
| 验证字符串不匹配 | `VerifyNotMatch` | 待验证字符串, 期望字符串 | [verifynotmatch.md](verifynotmatch.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifynotmatch/ |
| 验证字符串匹配 | `VerifyMatch` | 待验证字符串, 期望字符串 | [verifymatch.md](verifymatch.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifymatch/ |
| 验证小于 | `VerifyLessThan` | 实际值, 期望值 | [verifylessthan.md](verifylessthan.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifylessthan/ |
| 验证小于等于 | `VerifyLessThanOrEqual` | 实际值, 期望值 | [verifylessthanorequal.md](verifylessthanorequal.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifylessthanorequal/ |
| 验证条件为真 | `VerifyTrue` | 左值, 操作符, 右值 | [verifytrue.md](verifytrue.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifytrue/ |
| 验证相等 | `VerifyEqual` | 实际值, 期望值 | [verifyequal.md](verifyequal.md) | https://document.waimai.st.sankuai.com/commands/ui-commands/verifyequal/ |

## 测试场景常用

浮层搜索框输入下表「搜索名」：

| 搜索名 | 平台指令名 | reference |
|--------|-----------|-----------|
| `打开网页` | 打开网页 | [openurl.md](openurl.md) |
| `输入文本` | 输入文本 | [filltext.md](filltext.md) |
| `点击` / `点击元素` | 点击元素（推荐） | [clickelementmixed.md](clickelementmixed.md) |
