%% =====================================================================
%  FOCT数据读取和处理核心模块 (FOCT Core Reader)
%  
%  【功能描述】
%  - 读取Optovue FOCT格式的OCT数据文件
%  - 进行自适应对比度增强处理
%  - 输出为NIfTI医学影像标准格式
%  
%  【适用数据格式】
%  - FOCT格式：640×304×304 (float32)
%  - SSADA格式：160×400×400 (float32)
%  
%  【主要算法】
%  1. 基于直方图峰值的自适应对比度增强
%  2. 动态范围扩展和重新映射
%  3. 多层次可视化分析
%  
%  【输入要求】
%  - 数据文件夹：'foctdata\'
%  - 输出文件夹：'niidata\'
%  
%  【使用方法】
%  1. 设置filename变量为目标FOCT文件名
%  2. 确保输入输出文件夹存在
%  3. 直接运行脚本
%  
%  【输出文件】
%  - NIfTI格式3D医学影像：oct-[filename].nii
%  - 处理过程可视化图形
%  - 统计信息报告

%% =====================================================================

%% 1. 文件路径设置和数据读取
folder = 'foctdata\';                           % 数据文件夹路径（相对路径）
filename = 'AD_001_OD_3.foct';                  % 输入文件名，支持.foct或.ssada格式
                                               % 文件命名规则：AD_患者编号_眼别_扫描模式.foct
fid = fopen([folder,filename],'r');            % 以只读模式打开二进制文件
OCTA = fread(fid, [640 304*304], 'float32');   % 读取原始数据
                                               % .foct格式: 640×304×304
                                               % .ssada格式: 160×400×400
fclose(fid);                                   % 关闭文件句柄，释放系统资源
OCTA = reshape(OCTA, [640 304 304]);           % 将1D数据重构为3D矩阵 [深度×宽度×高度]
OCTA = OCTA(end:-1:1,:,:);                     % 沿深度方向翻转，调整为MATLAB标准显示方向

%% 2. 数据归一化和初步处理
%aa = OCTA(:,:,100);                           % 可选：查看单个切片用于调试

bb = max(max(max(OCTA)));                      % 找到整个3D数据的最大值
cc = im2uint8(OCTA/bb);                        % 归一化到[0,1]并转换为8位无符号整数[0,255]
%imwrite(cc(:,:,100),'test_1.png')             % 可选：保存测试图像
figure(1);                                     % 创建第一个图形窗口
imshow(cc(:,:,100))                            % 显示第100层切片（原始归一化后的图像）

%% 3. 自定义对比度增强算法
% 该算法通过分析整体直方图分布来增强图像对比度
flat = cc(:);                                  % 将3D数据展平为1D数组，用于直方图分析
hist = imhist(flat);                           % 计算整个数据集的直方图（256个bin）
[maxnum,maxloc] = max(hist);                   % 找到直方图的峰值位置（最常见的像素值）

% 显示关键统计信息
fprintf('=== 图像统计信息 ===\n');
fprintf('原始数据最大值: %.2f\n', bb);
fprintf('直方图峰值位置: %d (像素值)\n', maxloc-1);  % imhist索引从1开始，像素值从0开始
fprintf('峰值频次: %d\n', maxnum);
fprintf('原始图像动态范围: [%d, %d]\n', min(flat), max(flat));

dd = cc - maxloc;                              % 减去峰值，将直方图峰值移到0点
ee = dd*(256/(256-maxloc));                    % 重新缩放，将动态范围扩展到[0,255]
                                               % 这种方法可以增强低对比度区域的细节

% 显示增强后的统计信息
flatee_temp = ee(:);
fprintf('增强后动态范围: [%.1f, %.1f]\n', min(flatee_temp), max(flatee_temp));
fprintf('增强系数: %.2f\n', 256/(256-maxloc));
fprintf('========================\n');

% 计算处理前后的直方图用于对比分析
flatdd = dd(:);                                % 减去峰值后的展平数据
histdd = imhist(flatdd);                       % 中间处理步骤的直方图
flatee = ee(:);                                % 最终处理后的展平数据
histee = imhist(flatee);                       % 最终结果的直方图

figure(2);                                     % 创建第二个图形窗口
imshow(ee(:,:,100))                            % 显示增强后的第100层切片

%% 显示处理前后的直方图对比
figure(3);                                     % 创建第三个图形窗口用于直方图显示
subplot(2,2,1);                                % 2x2子图布局，第1个位置
bar(hist);                                     % 显示原始图像的直方图
title('原始图像直方图');
xlabel('像素值');
ylabel('频次');
grid on;

subplot(2,2,2);                                % 第2个位置
bar(histdd);                                   % 显示减去峰值后的直方图
title('减去峰值后的直方图');
xlabel('像素值');
ylabel('频次');
grid on;

subplot(2,2,3);                                % 第3个位置
bar(histee);                                   % 显示最终增强后的直方图
title('最终增强后的直方图');
xlabel('像素值');
ylabel('频次');
grid on;

subplot(2,2,4);                                % 第4个位置
% 叠加显示原始和增强后的直方图对比
hold on;
plot(0:255, hist, 'b-', 'LineWidth', 2, 'DisplayName', '原始');
plot(0:255, histee, 'r-', 'LineWidth', 2, 'DisplayName', '增强后');
hold off;
title('直方图对比');
xlabel('像素值');
ylabel('频次');
legend('show');
grid on;

%% 4. 数据输出为NIfTI格式
%figure;imagesc(OCTA(:,:,100));colormap(gray); set(gca,'xtick',[],'ytick',[]);  % 可选：另一种显示方式
wname = ['niidata\'];                          % 输出文件夹路径
%maxnum = max(max(max(OCTA)));                 % 备注：另一种归一化方法（已注释）
name = ['oct-',filename(1:end-6),'.nii'];      % 生成输出文件名
                                               % filename(1:end-6)去掉'.foct'扩展名
                                               % 例：'AD_001_OD_3.foct' -> 'oct-AD_001_OD_3.nii'
niftiwrite(ee, [wname,name]);                  % 将增强后的3D数据保存为NIfTI格式
                                               % NIfTI是医学影像标准格式，保持3D空间信息

%% 5. 备选输出方案（已注释）
% 以下代码可以将3D数据输出为JPG图像序列，每层一个文件
%OCTA = OCTA/maxnum;                           % 备选的归一化方法
%for i = 1:304                                % 遍历所有304层切片
%    wloc = [wname,num2str(i),'.jpg'];        % 生成文件名：1.jpg, 2.jpg, ..., 304.jpg
%    image = squeeze(ee(:,:,i));              % 提取第i层数据，去除单例维度
%    imwrite(image,wloc);                     % 保存为JPG格式
%end

%% 算法说明和优化建议
% 
% 【核心算法原理】
% 1. 直方图峰值检测：找到数据中最常见的像素值
% 2. 峰值偏移：将峰值移到0点，突出细节信息
% 3. 动态范围拉伸：重新映射到[0,255]范围，增强对比度