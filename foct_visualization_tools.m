function foct_visualization_tools()
%% =====================================================================
%  FOCT批量转换结果可视化工具集 (FOCT Visualization Tools)
%  
%  【功能描述】
%  - 批量生成FOCT转换结果的汇总可视化
%  - 支持大量文件的分页显示
%  - 自动排版和布局优化
%  - 多格式输出保存
%  
%  【主要特性】
%  - 智能网格布局：自动计算最佳行列数
%  - 分页管理：超过25个文件自动分页
%  - 文件名显示：去除扩展名，保持简洁
%  - 多格式保存：PNG和FIG格式并存
%  
%  【输入要求】
%  - foct_view文件夹：包含所有切片预览图像
%  - PNG格式图像：由批量转换生成的中间切片
%  
%  【输出结果】
%  - foct_conversion_summary.png：主汇总图
%  - foct_conversion_summary.fig：MATLAB图形文件
%  - foct_conversion_summary_page_N.png：分页图(如果需要)
%  
%  【使用方法】
%  foct_visualization_tools()
%  
%  【应用场景】
%  - 批量转换结果质量检查
%  - 数据集概览和统计
%  - 转换效果对比分析
%  - 项目汇报和展示

%% =====================================================================

fprintf('🎨 === FOCT转换结果可视化工具 ===\n');

%% 1. 环境检查和初始化
view_folder = 'foct_view';

% 检查输入文件夹
if ~exist(view_folder, 'dir')
    error('❌ 切片图像文件夹不存在: %s\n请先运行批量转换工具', view_folder);
end

% 获取所有切片图像文件
png_files = get_png_files(view_folder);
num_files = length(png_files);

if num_files == 0
    fprintf('❌ 在 %s 文件夹中未找到任何PNG文件\n', view_folder);
    fprintf('💡 提示：请先运行批量转换工具生成预览图像\n');
    return;
end

fprintf('📊 找到 %d 个切片图像，开始创建汇总可视化\n', num_files);

%% 2. 创建主汇总图
create_main_summary(png_files, view_folder, num_files);

%% 3. 处理大量文件的分页显示
if num_files > 25
    create_paged_summaries(png_files, view_folder);
end

%% 4. 生成统计报告
generate_visualization_report(num_files);

fprintf('🎉 可视化生成完成！\n');
fprintf('📁 请查看生成的汇总图和报告文件\n');

end

function png_files = get_png_files(view_folder)
%% 获取并排序PNG文件列表
    png_files = dir(fullfile(view_folder, '*.png'));
    
    % 按文件名排序以保持一致性
    [~, sort_idx] = sort({png_files.name});
    png_files = png_files(sort_idx);
end

function create_main_summary(png_files, view_folder, num_files)
%% 创建主汇总可视化图
    fprintf('🖼️  创建主汇总图...\n');
    
    % 确定显示的文件数量
    display_count = min(25, num_files);
    
    % 计算最优的网格布局
    [rows, cols] = calculate_optimal_grid(display_count);
    
    % 创建高质量图形窗口
    fig = figure('Position', [100, 100, 1400, 1000], ...
                 'Color', 'white', ...
                 'Name', 'FOCT转换结果汇总', ...
                 'NumberTitle', 'off');
    
    % 逐个显示图像
    for i = 1:display_count
        img_path = fullfile(view_folder, png_files(i).name);
        
        try
            img = imread(img_path);
            
            subplot(rows, cols, i);
            imshow(img, []);
            
            % 提取并格式化文件名
            [~, base_name, ~] = fileparts(png_files(i).name);
            formatted_name = format_filename_for_display(base_name);
            
            title(formatted_name, 'Interpreter', 'none', ...
                  'FontSize', 8, 'FontWeight', 'normal');
            
            % 移除坐标轴
            axis off;
            
        catch ME
            fprintf('⚠️  无法读取图像: %s (%s)\n', png_files(i).name, ME.message);
        end
    end
    
    % 设置总标题
    main_title = sprintf('FOCT转换结果预览汇总\\n显示前%d个文件的中间切片 (共%d个文件)', ...
                        display_count, num_files);
    sgtitle(main_title, 'FontSize', 14, 'FontWeight', 'bold');
    
    % 调整子图间距
    adjust_subplot_spacing();
    
    % 保存汇总图
    save_summary_figure(fig, 'foct_conversion_summary');
    
    fprintf('✅ 主汇总图保存完成\n');
end

function [rows, cols] = calculate_optimal_grid(num_items)
%% 计算最优网格布局
    if num_items <= 1
        rows = 1; cols = 1;
    elseif num_items <= 4
        rows = 2; cols = 2;
    elseif num_items <= 9
        rows = 3; cols = 3;
    elseif num_items <= 16
        rows = 4; cols = 4;
    else
        % 对于更多项目，计算接近正方形的布局
        rows = ceil(sqrt(num_items));
        cols = ceil(num_items / rows);
    end
end

function formatted_name = format_filename_for_display(base_name)
%% 格式化文件名以便显示
    % 移除常见的前缀和后缀
    formatted_name = base_name;
    
    % 如果名称太长，进行缩写
    if length(formatted_name) > 20
        % 保留重要部分，省略中间
        if contains(formatted_name, '_')
            parts = strsplit(formatted_name, '_');
            if length(parts) >= 3
                formatted_name = [parts{1} '_' parts{2} '_..._' parts{end}];
            end
        end
    end
    
    % 如果仍然太长，直接截断
    if length(formatted_name) > 25
        formatted_name = [formatted_name(1:22) '...'];
    end
end

function adjust_subplot_spacing()
%% 调整子图间距
    % 设置子图之间的间距
    set(gcf, 'DefaultAxesPosition', [0.1, 0.1, 0.8, 0.8]);
    
    % 紧凑布局
    try
        % MATLAB R2019b及以后版本
        tiledlayout('tight');
    catch
        % 较旧版本的替代方案
        subplot_spacing = 0.02;
        set(gca, 'Position', get(gca, 'Position') + [-subplot_spacing, -subplot_spacing, ...
                                                     2*subplot_spacing, 2*subplot_spacing]);
    end
end

function save_summary_figure(fig, base_filename)
%% 保存汇总图形
    try
        % 保存PNG格式（用于报告和展示）
        png_filename = [base_filename '.png'];
        saveas(fig, png_filename, 'png');
        fprintf('   📄 PNG格式: %s\n', png_filename);
        
        % 保存FIG格式（用于MATLAB后续编辑）
        fig_filename = [base_filename '.fig'];
        saveas(fig, fig_filename, 'fig');
        fprintf('   📄 FIG格式: %s\n', fig_filename);
        
        % 可选：保存高分辨率PDF格式
        try
            pdf_filename = [base_filename '.pdf'];
            saveas(fig, pdf_filename, 'pdf');
            fprintf('   📄 PDF格式: %s\n', pdf_filename);
        catch
            % PDF保存可能失败，不是关键错误
        end
        
    catch ME
        fprintf('⚠️  图形保存时出现问题: %s\n', ME.message);
    end
end

function create_paged_summaries(png_files, view_folder)
%% 为大量文件创建分页汇总
    fprintf('📖 文件数量较多，创建分页汇总图...\n');
    
    files_per_page = 25;
    total_files = length(png_files);
    total_pages = ceil(total_files / files_per_page);
    
    fprintf('   总计 %d 个文件，将创建 %d 页汇总图\n', total_files, total_pages);
    
    for page = 1:total_pages
        fprintf('   正在创建第 %d/%d 页...', page, total_pages);
        
        % 计算当前页的文件范围
        start_idx = (page - 1) * files_per_page + 1;
        end_idx = min(page * files_per_page, total_files);
        current_files = png_files(start_idx:end_idx);
        
        % 创建当前页的可视化
        create_single_page_summary(current_files, view_folder, page, total_pages);
        
        fprintf(' 完成\n');
    end
    
    fprintf('✅ 所有分页汇总图创建完成\n');
end

function create_single_page_summary(current_files, view_folder, page_num, total_pages)
%% 创建单页汇总图
    num_current = length(current_files);
    [rows, cols] = calculate_optimal_grid(num_current);
    
    % 创建图形窗口
    fig = figure('Position', [100, 100, 1400, 1000], ...
                 'Color', 'white', ...
                 'Name', sprintf('FOCT汇总-第%d页', page_num), ...
                 'NumberTitle', 'off');
    
    % 显示当前页的所有图像
    for i = 1:num_current
        img_path = fullfile(view_folder, current_files(i).name);
        
        try
            img = imread(img_path);
            
            subplot(rows, cols, i);
            imshow(img, []);
            
            [~, base_name, ~] = fileparts(current_files(i).name);
            formatted_name = format_filename_for_display(base_name);
            
            title(formatted_name, 'Interpreter', 'none', ...
                  'FontSize', 8, 'FontWeight', 'normal');
            axis off;
            
        catch ME
            fprintf('\n⚠️  页面%d: 无法读取图像 %s (%s)\n', ...
                    page_num, current_files(i).name, ME.message);
        end
    end
    
    % 设置页面标题
    page_title = sprintf('FOCT转换结果预览 - 第%d页 (共%d页)\\n文件 %d-%d', ...
                        page_num, total_pages, ...
                        (page_num-1)*25+1, (page_num-1)*25+num_current);
    sgtitle(page_title, 'FontSize', 14, 'FontWeight', 'bold');
    
    % 调整布局
    adjust_subplot_spacing();
    
    % 保存分页图
    page_filename = sprintf('foct_conversion_summary_page_%d', page_num);
    save_summary_figure(fig, page_filename);
end

function generate_visualization_report(num_files)
%% 生成可视化统计报告
    report_filename = 'foct_visualization_report.txt';
    fid = fopen(report_filename, 'w');
    
    fprintf(fid, '=== FOCT转换结果可视化报告 ===\n');
    fprintf(fid, '生成时间: %s\n\n', datestr(now));
    
    fprintf(fid, '可视化统计:\n');
    fprintf(fid, '  处理文件数量: %d 个PNG图像\n', num_files);
    
    if num_files <= 25
        fprintf(fid, '  生成文件:\n');
        fprintf(fid, '    - foct_conversion_summary.png (主汇总图)\n');
        fprintf(fid, '    - foct_conversion_summary.fig (MATLAB格式)\n');
        try
            fprintf(fid, '    - foct_conversion_summary.pdf (高分辨率PDF)\n');
        catch
        end
    else
        total_pages = ceil(num_files / 25);
        fprintf(fid, '  分页显示: %d 页 (每页最多25个文件)\n', total_pages);
        fprintf(fid, '  生成文件:\n');
        fprintf(fid, '    - foct_conversion_summary.png (主汇总图)\n');
        fprintf(fid, '    - foct_conversion_summary.fig (MATLAB格式)\n');
        
        for page = 1:total_pages
            fprintf(fid, '    - foct_conversion_summary_page_%d.png (第%d页)\n', page, page);
        end
    end
    
    fprintf(fid, '\n文件布局说明:\n');
    fprintf(fid, '  - 自动计算最优网格布局\n');
    fprintf(fid, '  - 按文件名字母顺序排列\n');
    fprintf(fid, '  - 长文件名自动缩写显示\n');
    fprintf(fid, '  - 紧凑布局最大化图像显示\n\n');
    
    fprintf(fid, '使用说明:\n');
    fprintf(fid, '1. PNG文件用于报告和演示\n');
    fprintf(fid, '2. FIG文件可在MATLAB中进一步编辑\n');
    fprintf(fid, '3. PDF文件适合高质量打印\n');
    fprintf(fid, '4. 分页图便于详细检查每个文件\n\n');
    
    fprintf(fid, '建议:\n');
    fprintf(fid, '1. 检查汇总图中的异常图像\n');
    fprintf(fid, '2. 对质量有问题的文件进行单独处理\n');
    fprintf(fid, '3. 根据预览结果调整转换参数\n');
    
    fclose(fid);
    
    fprintf('📋 可视化报告已保存: %s\n', report_filename);
end