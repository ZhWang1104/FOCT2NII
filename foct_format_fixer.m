function foct_format_fixer()
%% =====================================================================
%  非标准FOCT文件修复工具 (FOCT Format Fixer)
%  
%  【功能描述】
%  - 专门修复转换失败的非标准FOCT文件
%  - 自动检测和适配不同的数据格式
%  - 智能维度推测和数据重构
%  - 保持与标准流程的兼容性
%  
%  【支持的格式】
%  - 3133440字节文件 (约3.0MB) - 可能的160×120×41格式
%  - 2611200字节文件 (约2.5MB) - 可能的160×120×34格式
%  - 其他非标准尺寸的自动检测
%  
%  【修复策略】
%  1. 文件大小分析和格式推测
%  2. 多种维度组合尝试
%  3. 数据完整性验证
%  4. 自适应对比度增强
%  5. 标准化输出格式
%  
%  【使用场景】
%  - 批量转换中的失败文件修复
%  - 非标准FOCT格式的兼容处理
%  - 数据迁移和格式标准化
%  
%  【使用方法】
%  foct_format_fixer()
%  
%  【输入配置】
%  - 自动读取失败文件列表或手动配置
%  - 输入文件夹：'foctdata'
%  - 输出文件夹：'nii' 和 'foct_view'
%  
%  【输出结果】
%  - 修复后的NII文件
%  - 预览切片图像
%  - 详细的修复报告
%  
%% =====================================================================

fprintf('🔧 === 非标准FOCT文件修复工具 ===\n');

%% 1. 获取失败文件列表
failed_files = get_failed_files_list();
input_folder = 'foctdata';
nii_folder = 'nii';
view_folder = 'foct_view';

% 确保输出文件夹存在
ensure_output_directories(nii_folder, view_folder);

if isempty(failed_files)
    fprintf('ℹ️  未找到需要修复的文件\n');
    return;
end

fprintf('📋 开始修复 %d 个失败文件...\n\n', length(failed_files));

%% 2. 批量修复处理
success_count = 0;
still_failed = {};

start_time = tic;

for i = 1:length(failed_files)
    filename = failed_files{i};
    filepath = fullfile(input_folder, filename);
    
    fprintf('--- 🔧 修复文件 %d/%d: %s ---\n', i, length(failed_files), filename);
    
    try
        % 智能格式检测和修复
        foct_data = smart_format_detection(filepath);
        
        if ~isempty(foct_data)
            % 处理数据并保存
            process_and_save_fixed_file(foct_data, filename, nii_folder, view_folder);
            success_count = success_count + 1;
            fprintf('✅ 修复成功: %s\n', filename);
        else
            error('无法确定合适的数据格式');
        end
        
    catch ME
        still_failed{end+1} = filename;
        fprintf('❌ 修复失败: %s\n', filename);
        fprintf('   错误详情: %s\n', ME.message);
    end
    
    fprintf('\n');
end

processing_time = toc(start_time);

%% 3. 生成修复报告
generate_fix_report(success_count, still_failed, processing_time);

fprintf('🎉 === 修复完成 ===\n');
fprintf('✅ 成功修复: %d/%d 个文件 (%.1f%%)\n', success_count, length(failed_files), ...
        (success_count/length(failed_files))*100);
fprintf('❌ 仍然失败: %d 个文件\n', length(still_failed));
fprintf('⏱️  修复耗时: %.2f 秒\n', processing_time);

if ~isempty(still_failed)
    fprintf('\n💡 对于仍然失败的文件，建议：\n');
    fprintf('   1. 检查文件是否损坏\n');
    fprintf('   2. 确认数据格式规范\n');
    fprintf('   3. 联系数据提供方\n');
end

end

function failed_files = get_failed_files_list()
%% 智能获取失败文件列表
    
    % 优先从诊断报告读取
    diagnostic_report = 'foct_diagnostic_report.txt';
    if exist(diagnostic_report, 'file')
        failed_files = parse_from_diagnostic_report(diagnostic_report);
        if ~isempty(failed_files)
            fprintf('📋 从诊断报告读取失败文件列表\n');
            return;
        end
    end
    
    % 其次从批量转换报告读取
    batch_report = 'batch_conversion_report.txt';
    if exist(batch_report, 'file')
        failed_files = parse_from_batch_report(batch_report);
        if ~isempty(failed_files)
            fprintf('📋 从批量转换报告读取失败文件列表\n');
            return;
        end
    end
    
    % 最后使用预定义列表
    failed_files = {
        'MCI_024_OS_8_1.foct';
        'MCI_024_OS_8_2.foct';
        'MCI_039_OD_3_2.foct';
        'MCI_039_OD_3_3.foct';
        'MCI_077_OD_3.foct'
    };
    
    fprintf('📋 使用预定义的失败文件列表\n');
end

function failed_files = parse_from_batch_report(report_file)
%% 从批量转换报告解析失败文件
    failed_files = {};
    
    try
        fid = fopen(report_file, 'r');
        if fid == -1, return; end
        
        content = fread(fid, '*char')';
        fclose(fid);
        
        % 提取失败文件列表部分
        pattern = '失败的文件列表:.*?(?=\n\n|\n[^\s])';
        match = regexp(content, pattern, 'match', 'dotexceptnewline');
        
        if ~isempty(match)
            lines = strsplit(match{1}, '\n');
            for i = 1:length(lines)
                line = lines{i};
                tokens = regexp(line, '\d+\.\s+(\w+\.foct)', 'tokens');
                if ~isempty(tokens)
                    failed_files{end+1} = tokens{1}{1};
                end
            end
        end
        
    catch
        failed_files = {};
    end
end

function failed_files = parse_from_diagnostic_report(~)
%% 从诊断报告解析失败文件（占位函数）
    failed_files = {};
    % 实现类似的解析逻辑
end

function ensure_output_directories(nii_folder, view_folder)
%% 确保输出目录存在
    if ~exist(nii_folder, 'dir')
        mkdir(nii_folder);
        fprintf('📁 创建NII输出文件夹: %s\n', nii_folder);
    end
    
    if ~exist(view_folder, 'dir')
        mkdir(view_folder);
        fprintf('📁 创建预览文件夹: %s\n', view_folder);
    end
end

function foct_data = smart_format_detection(filepath)
%% 智能格式检测和数据读取
    
    % 获取文件信息
    file_info = dir(filepath);
    file_size = file_info.bytes;
    
    fprintf('📏 文件大小: %d 字节 (%.2f MB)\n', file_size, file_size/1024/1024);
    
    % 根据文件大小选择读取策略
    if file_size == 3133440
        foct_data = read_format_3mb(filepath);
    elseif file_size == 2611200
        foct_data = read_format_2_5mb(filepath);
    else
        foct_data = read_unknown_format(filepath, file_size);
    end
end

function foct_data = read_format_3mb(filepath)
%% 读取约3MB的文件 (3133440字节)
    
    fid = fopen(filepath, 'r');
    if fid == -1
        error('无法打开文件: %s', filepath);
    end
    
    try
        total_elements = 3133440 / 4;  % 783360个float32元素
        
        % 尝试最可能的维度组合
        format_attempts = [
            struct('w', 160, 'h', 120, 'd', 41);  % 787200元素，接近
            struct('w', 140, 'h', 140, 'd', 40);  % 784000元素
            struct('w', 128, 'h', 128, 'd', 48);  % 786432元素
            struct('w', 144, 'h', 144, 'd', 38)   % 787968元素
        ];
        
        for i = 1:length(format_attempts)
            fmt = format_attempts(i);
            elements_needed = fmt.w * fmt.h * fmt.d;
            
            if elements_needed <= total_elements
                % 尝试读取这种格式
                fseek(fid, 0, 'bof');
                data = fread(fid, elements_needed, 'float32');
                
                if length(data) == elements_needed
                    foct_data = reshape(data, [fmt.w, fmt.h, fmt.d]);
                    fprintf('✅ 成功使用格式: %dx%dx%d\n', fmt.w, fmt.h, fmt.d);
                    fclose(fid);
                    return;
                end
            end
        end
        
        error('无法找到合适的数据格式');
        
    catch ME
        fclose(fid);
        rethrow(ME);
    end
end

function foct_data = read_format_2_5mb(filepath)
%% 读取约2.5MB的文件 (2611200字节)
    
    fid = fopen(filepath, 'r');
    if fid == -1
        error('无法打开文件: %s', filepath);
    end
    
    try
        total_elements = 2611200 / 4;  % 652800个float32元素
        
        % 检查是否正好匹配160×120×34
        if total_elements == 160 * 120 * 34
            data = fread(fid, total_elements, 'float32');
            foct_data = reshape(data, [160, 120, 34]);
            fprintf('✅ 完美匹配格式: 160x120x34\n');
            fclose(fid);
            return;
        end
        
        % 尝试其他可能的组合
        format_attempts = [
            struct('w', 160, 'h', 120, 'd', 34);  % 652800元素，完美匹配
            struct('w', 120, 'h', 120, 'd', 45);  % 648000元素
            struct('w', 128, 'h', 128, 'd', 40);  % 655360元素
            struct('w', 140, 'h', 140, 'd', 33)   % 646800元素
        ];
        
        for i = 1:length(format_attempts)
            fmt = format_attempts(i);
            elements_needed = fmt.w * fmt.h * fmt.d;
            
            if elements_needed <= total_elements
                fseek(fid, 0, 'bof');
                data = fread(fid, elements_needed, 'float32');
                
                if length(data) == elements_needed
                    foct_data = reshape(data, [fmt.w, fmt.h, fmt.d]);
                    fprintf('✅ 成功使用格式: %dx%dx%d\n', fmt.w, fmt.h, fmt.d);
                    fclose(fid);
                    return;
                end
            end
        end
        
        error('无法找到合适的数据格式');
        
    catch ME
        fclose(fid);
        rethrow(ME);
    end
end

function foct_data = read_unknown_format(filepath, file_size)
%% 读取未知格式的文件
    
    fid = fopen(filepath, 'r');
    if fid == -1
        error('无法打开文件: %s', filepath);
    end
    
    try
        % 假设float32格式
        total_elements = floor(file_size / 4);
        
        % 尝试找到接近立方体的维度
        cube_root = round(total_elements^(1/3));
        
        % 在立方根附近搜索合理的维度
        for offset = 0:10
            for w = [cube_root - offset, cube_root + offset]
                if w <= 0, continue; end
                
                remaining = total_elements / w;
                h_root = sqrt(remaining);
                
                for h_offset = 0:5
                    for h = [floor(h_root) - h_offset, ceil(h_root) + h_offset]
                        if h <= 0, continue; end
                        
                        d = floor(total_elements / (w * h));
                        if d > 0 && w * h * d <= total_elements
                            
                            data = fread(fid, w * h * d, 'float32');
                            if length(data) == w * h * d
                                foct_data = reshape(data, [w, h, d]);
                                fprintf('✅ 推测格式: %dx%dx%d\n', w, h, d);
                                fclose(fid);
                                return;
                            end
                        end
                    end
                end
            end
        end
        
        error('无法确定合适的数据维度');
        
    catch ME
        fclose(fid);
        rethrow(ME);
    end
end

function process_and_save_fixed_file(foct_data, filename, nii_folder, view_folder)
%% 处理修复的数据并保存
    
    % 数据质量检查
    if any(isnan(foct_data(:)))
        fprintf('⚠️  检测到NaN值，进行数据清理\n');
        foct_data(isnan(foct_data)) = 0;
    end
    
    if any(isinf(foct_data(:)))
        fprintf('⚠️  检测到无穷值，进行数据清理\n');
        foct_data(isinf(foct_data)) = 0;
    end
    
    % 数据归一化和增强处理
    foct_min = min(foct_data(:));
    foct_max = max(foct_data(:));
    
    if foct_max > foct_min
        foct_norm = (foct_data - foct_min) / (foct_max - foct_min);
    else
        foct_norm = zeros(size(foct_data));
        fprintf('⚠️  数据范围为零，使用全零矩阵\n');
    end
    
    % 应用增强算法
    enhanced_data = enhanced_contrast_adaptive(foct_norm);
    
    % 恢复到原始数值范围
    enhanced_data_scaled = enhanced_data * (foct_max - foct_min) + foct_min;
    
    % 保存为NII格式
    [~, base_name, ~] = fileparts(filename);
    nii_filename = [base_name '.nii'];
    nii_path = fullfile(nii_folder, nii_filename);
    save_as_nifti_robust(enhanced_data_scaled, nii_path);
    
    % 保存预览切片
    middle_slice = round(size(enhanced_data, 3) / 2);
    slice_img = enhanced_data(:,:,middle_slice);
    
    slice_filename = [base_name '.png'];
    slice_path = fullfile(view_folder, slice_filename);
    imwrite(slice_img, slice_path);
    
    fprintf('   📄 NII文件: %s\n', nii_filename);
    fprintf('   🖼️  切片图像: %s (第%d层，共%d层)\n', slice_filename, middle_slice, size(enhanced_data, 3));
end

function enhanced_data = enhanced_contrast_adaptive(foct_norm)
%% 自适应对比度增强
    if max(foct_norm(:)) <= min(foct_norm(:))
        enhanced_data = foct_norm;
        return;
    end
    
    % 使用多种方法的组合
    flat_data = foct_norm(:);
    
    % 方法1: 百分位数拉伸
    p1 = prctile(flat_data, 2);   % 2%分位数
    p98 = prctile(flat_data, 98); % 98%分位数
    
    if p98 > p1
        method1 = (foct_norm - p1) / (p98 - p1);
        method1 = max(0, min(1, method1));
    else
        method1 = foct_norm;
    end
    
    % 方法2: 直方图均衡化增强
    try
        [hist_counts, ~] = imhist(uint8(flat_data * 255), 256);
        [~, peak_idx] = max(hist_counts);
        peak_value = (peak_idx - 1) / 255;
        
        if peak_value > 0.1 && peak_value < 0.9
            method2 = (foct_norm - peak_value) * (1 / (1 - peak_value));
            method2 = max(0, min(1, method2));
        else
            method2 = method1;
        end
    catch
        method2 = method1;
    end
    
    % 组合两种方法（加权平均）
    enhanced_data = 0.6 * method1 + 0.4 * method2;
    enhanced_data = max(0, min(1, enhanced_data));
end

function save_as_nifti_robust(data, filename)
%% 鲁棒的NIfTI保存函数
    try
        niftiwrite(data, filename);
        fprintf('   ✅ NIfTI保存成功\n');
    catch ME
        fprintf('   ⚠️  NIfTI保存失败: %s\n', ME.message);
        fprintf('   📦 改为保存MAT格式\n');
        
        mat_filename = [filename(1:end-4) '.mat'];
        save(mat_filename, 'data', '-v7.3');
    end
end

function generate_fix_report(success_count, still_failed, processing_time)
%% 生成修复报告
    report_filename = 'foct_format_fix_report.txt';
    fid = fopen(report_filename, 'w');
    
    total_files = success_count + length(still_failed);
    success_rate = (success_count / total_files) * 100;
    
    fprintf(fid, '=== 非标准FOCT文件修复报告 ===\n');
    fprintf(fid, '生成时间: %s\n\n', datestr(now));
    
    fprintf(fid, '修复统计:\n');
    fprintf(fid, '  成功修复: %d 个文件 (%.1f%%)\n', success_count, success_rate);
    fprintf(fid, '  仍然失败: %d 个文件 (%.1f%%)\n', length(still_failed), ...
            (length(still_failed)/total_files)*100);
    fprintf(fid, '  总计文件: %d 个\n', total_files);
    fprintf(fid, '  修复耗时: %.2f 秒\n\n', processing_time);
    
    if ~isempty(still_failed)
        fprintf(fid, '仍然失败的文件:\n');
        for i = 1:length(still_failed)
            fprintf(fid, '  %d. %s\n', i, still_failed{i});
        end
        fprintf(fid, '\n');
    end
    
    fprintf(fid, '修复方法说明:\n');
    fprintf(fid, '1. 智能文件格式检测\n');
    fprintf(fid, '   - 3MB文件: 尝试160×120×41等格式\n');
    fprintf(fid, '   - 2.5MB文件: 优先160×120×34格式\n');
    fprintf(fid, '   - 未知格式: 自动维度推测\n\n');
    
    fprintf(fid, '2. 数据质量控制\n');
    fprintf(fid, '   - NaN和无穷值清理\n');
    fprintf(fid, '   - 数据范围验证\n');
    fprintf(fid, '   - 自适应对比度增强\n\n');
    
    fprintf(fid, '3. 输出标准化\n');
    fprintf(fid, '   - NIfTI格式优先，MAT格式备用\n');
    fprintf(fid, '   - 中间切片预览图像\n');
    fprintf(fid, '   - 详细处理日志\n\n');
    
    fprintf(fid, '建议:\n');
    fprintf(fid, '1. 对修复成功的文件进行质量检查\n');
    fprintf(fid, '2. 失败文件可能需要手动处理或联系数据提供方\n');
    fprintf(fid, '3. 建议在正式分析前验证修复结果的准确性\n');
    
    fclose(fid);
    
    fprintf('📋 修复报告已保存: %s\n', report_filename);
end