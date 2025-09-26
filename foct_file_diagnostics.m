function foct_file_diagnostics()
%% =====================================================================
%  FOCT文件格式诊断工具 (FOCT File Diagnostics)
%  
%  【功能描述】
%  - 诊断FOCT文件转换失败的原因
%  - 分析文件大小、格式和数据完整性
%  - 提供可能的修复建议
%  - 支持多种数据格式检测
%  
%  【诊断项目】
%  1. 文件存在性检查
%  2. 文件大小分析
%  3. 数据格式推测
%  4. 数据范围和类型检查
%  5. 可能的维度组合计算
%  
%  【支持的诊断】
%  - 标准FOCT格式 (640×304×304)
%  - 非标准格式自动识别
%  - 损坏文件检测
%  - 数据类型验证
%  
%  【使用方法】
%  foct_file_diagnostics()
%  
%  【输入配置】
%  - 在代码中修改failed_files列表
%  - 或从batch_conversion_report.txt自动读取
%  
%  【输出结果】
%  - 详细的诊断报告
%  - 修复建议
%  - 可能的数据维度
%  

%% =====================================================================

fprintf('🔍 === FOCT文件格式诊断工具 ===\n');

%% 1. 获取失败文件列表
failed_files = get_failed_files_list();
input_folder = 'foctdata';

if isempty(failed_files)
    fprintf('ℹ️  未找到需要诊断的文件\n');
    return;
end

fprintf('📋 开始诊断 %d 个失败文件...\n\n', length(failed_files));

%% 2. 逐个诊断文件
diagnostic_results = {};

for i = 1:length(failed_files)
    filename = failed_files{i};
    filepath = fullfile(input_folder, filename);
    
    fprintf('--- 📁 诊断文件 %d: %s ---\n', i, filename);
    
    % 检查文件是否存在
    if ~exist(filepath, 'file')
        fprintf('❌ 文件不存在: %s\n', filepath);
        diagnostic_results{i} = struct('filename', filename, 'status', 'not_found');
        continue;
    end
    
    % 执行详细诊断
    result = diagnose_single_file(filepath, filename);
    diagnostic_results{i} = result;
    
    fprintf('\n');
end

%% 3. 生成诊断汇总报告
generate_diagnostic_report(diagnostic_results);

fprintf('✅ === 诊断完成 ===\n');
fprintf('📊 详细报告已保存到 foct_diagnostic_report.txt\n');

end

function failed_files = get_failed_files_list()
%% 获取失败文件列表（自动读取或手动配置）
    
    % 首先尝试从批量转换报告中读取
    report_file = 'batch_conversion_report.txt';
    
    if exist(report_file, 'file')
        failed_files = parse_failed_files_from_report(report_file);
        if ~isempty(failed_files)
            fprintf('📋 从报告文件读取到 %d 个失败文件\n', length(failed_files));
            return;
        end
    end
    
    % 备用：手动配置的已知失败文件
    failed_files = {
        'MCI_024_OS_8_1.foct';
        'MCI_024_OS_8_2.foct';
        'MCI_039_OD_3_2.foct';
        'MCI_039_OD_3_3.foct';
        'MCI_077_OD_3.foct'
    };
    
    fprintf('📋 使用预配置的失败文件列表 (%d 个文件)\n', length(failed_files));
end

function failed_files = parse_failed_files_from_report(report_file)
%% 从批量转换报告中解析失败文件列表
    failed_files = {};
    
    try
        fid = fopen(report_file, 'r');
        if fid == -1
            return;
        end
        
        in_failed_section = false;
        while ~feof(fid)
            line = fgetl(fid);
            if contains(line, '失败的文件列表:')
                in_failed_section = true;
                continue;
            end
            
            if in_failed_section
                if contains(line, '输出文件夹:') || isempty(strtrim(line))
                    break;
                end
                
                % 解析文件名 (格式: "  1. filename.foct")
                tokens = regexp(line, '\d+\.\s+(\w+\.foct)', 'tokens');
                if ~isempty(tokens)
                    failed_files{end+1} = tokens{1}{1};
                end
            end
        end
        
        fclose(fid);
        
    catch ME
        fprintf('⚠️  读取报告文件失败: %s\n', ME.message);
        failed_files = {};
    end
end

function result = diagnose_single_file(filepath, filename)
%% 诊断单个文件的详细信息
    
    result = struct();
    result.filename = filename;
    result.status = 'diagnosed';
    
    % 1. 文件大小分析
    file_info = dir(filepath);
    file_size = file_info.bytes;
    fprintf('📏 文件大小: %d 字节 (%.2f MB)\n', file_size, file_size/1024/1024);
    
    % 计算预期大小
    expected_size = 640 * 304 * 304 * 4; % float32 = 4字节
    fprintf('📐 标准大小: %d 字节 (%.2f MB)\n', expected_size, expected_size/1024/1024);
    
    result.file_size = file_size;
    result.expected_size = expected_size;
    result.size_match = (file_size == expected_size);
    
    if result.size_match
        fprintf('✅ 文件大小符合标准FOCT格式\n');
    else
        size_diff = file_size - expected_size;
        fprintf('❌ 文件大小异常 (差异: %d 字节, %.1f%%)\n', ...
                size_diff, (size_diff/expected_size)*100);
        
        % 分析可能的格式
        possible_formats = analyze_possible_formats(file_size);
        result.possible_formats = possible_formats;
        
        if ~isempty(possible_formats)
            fprintf('🔧 可能的数据格式:\n');
            for j = 1:size(possible_formats, 1)
                fmt = possible_formats(j, :);
                fprintf('   - %dx%dx%d (%s)\n', fmt(1), fmt(2), fmt(3), fmt{4});
            end
        end
    end
    
    % 2. 数据内容分析
    data_analysis = analyze_file_content(filepath);
    result.data_analysis = data_analysis;
    
    % 3. 提供修复建议
    suggestions = generate_fix_suggestions(result);
    result.suggestions = suggestions;
    
    fprintf('💡 修复建议:\n');
    for j = 1:length(suggestions)
        fprintf('   %d. %s\n', j, suggestions{j});
    end
end

function possible_formats = analyze_possible_formats(file_size)
%% 分析可能的数据格式
    possible_formats = {};
    
    % 假设float32格式 (4字节)
    total_elements = file_size / 4;
    
    if mod(total_elements, 1) ~= 0
        % 尝试其他数据类型
        if mod(file_size, 2) == 0
            possible_formats{end+1, 1} = file_size/2;
            possible_formats{end, 2} = 1;
            possible_formats{end, 3} = 1;
            possible_formats{end, 4} = 'uint16';
        end
        return;
    end
    
    total_elements = round(total_elements);
    
    % 常见的医学影像尺寸
    common_sizes = [64, 128, 160, 256, 304, 320, 400, 512, 640, 1024];
    
    for w = common_sizes
        for h = common_sizes
            if mod(total_elements, (w * h)) == 0
                d = total_elements / (w * h);
                if d > 0 && d < 1000 && d == round(d) % 合理的深度范围
                    possible_formats{end+1, 1} = w;
                    possible_formats{end, 2} = h;
                    possible_formats{end, 3} = d;
                    possible_formats{end, 4} = 'float32';
                end
            end
        end
    end
    
    % 按相似度排序（与标准格式的接近程度）
    if ~isempty(possible_formats)
        standard_vol = 640 * 304 * 304;
        scores = zeros(size(possible_formats, 1), 1);
        
        for i = 1:size(possible_formats, 1)
            vol = possible_formats{i,1} * possible_formats{i,2} * possible_formats{i,3};
            scores(i) = abs(log(vol/standard_vol)); % 对数比值的绝对值
        end
        
        [~, idx] = sort(scores);
        possible_formats = possible_formats(idx, :);
        
        % 只保留最可能的前5个
        if size(possible_formats, 1) > 5
            possible_formats = possible_formats(1:5, :);
        end
    end
end

function data_analysis = analyze_file_content(filepath)
%% 分析文件内容
    data_analysis = struct();
    
    try
        fid = fopen(filepath, 'r');
        
        % 读取前100个float32值
        sample_float32 = fread(fid, 100, 'float32');
        
        % 重新定位到文件开始
        fseek(fid, 0, 'bof');
        
        % 读取前200个uint16值
        sample_uint16 = fread(fid, 200, 'uint16');
        
        % 重新定位到文件开始
        fseek(fid, 0, 'bof');
        
        % 读取前400个uint8值
        sample_uint8 = fread(fid, 400, 'uint8');
        
        fclose(fid);
        
        % 分析float32数据
        if ~isempty(sample_float32)
            data_analysis.float32.range = [min(sample_float32), max(sample_float32)];
            data_analysis.float32.mean = mean(sample_float32);
            data_analysis.float32.has_nan = any(isnan(sample_float32));
            data_analysis.float32.has_inf = any(isinf(sample_float32));
            
            fprintf('📊 Float32样本: 范围[%.3f, %.3f], 均值%.3f', ...
                    data_analysis.float32.range(1), data_analysis.float32.range(2), ...
                    data_analysis.float32.mean);
            if data_analysis.float32.has_nan
                fprintf(' [含NaN]');
            end
            if data_analysis.float32.has_inf
                fprintf(' [含Inf]');
            end
            fprintf('\n');
        end
        
        % 分析uint16数据
        if ~isempty(sample_uint16)
            data_analysis.uint16.range = [min(sample_uint16), max(sample_uint16)];
            data_analysis.uint16.mean = mean(sample_uint16);
            
            fprintf('📊 Uint16样本: 范围[%d, %d], 均值%.1f\n', ...
                    data_analysis.uint16.range(1), data_analysis.uint16.range(2), ...
                    data_analysis.uint16.mean);
        end
        
        % 分析uint8数据
        if ~isempty(sample_uint8)
            data_analysis.uint8.range = [min(sample_uint8), max(sample_uint8)];
            data_analysis.uint8.mean = mean(sample_uint8);
            
            fprintf('📊 Uint8样本: 范围[%d, %d], 均值%.1f\n', ...
                    data_analysis.uint8.range(1), data_analysis.uint8.range(2), ...
                    data_analysis.uint8.mean);
        end
        
    catch ME
        fprintf('⚠️  数据分析失败: %s\n', ME.message);
        data_analysis.error = ME.message;
    end
end

function suggestions = generate_fix_suggestions(result)
%% 生成修复建议
    suggestions = {};
    
    if result.size_match
        suggestions{end+1} = '文件大小正确，可能是数据内容问题，检查数据完整性';
        suggestions{end+1} = '尝试使用不同的读取参数或数据类型';
    else
        suggestions{end+1} = '文件大小异常，可能是非标准FOCT格式';
        
        if isfield(result, 'possible_formats') && ~isempty(result.possible_formats)
            best_format = result.possible_formats(1, :);
            suggestions{end+1} = sprintf('推荐尝试 %dx%dx%d (%s) 格式', ...
                                       best_format{1}, best_format{2}, best_format{3}, best_format{4});
            suggestions{end+1} = '使用fix_failed_foct_files.m工具进行自动修复';
        else
            suggestions{end+1} = '无法确定合适的数据格式，可能是损坏文件';
        end
    end
    
    if isfield(result, 'data_analysis')
        if isfield(result.data_analysis, 'float32')
            if result.data_analysis.float32.has_nan
                suggestions{end+1} = '检测到NaN值，需要数据清理';
            end
            if result.data_analysis.float32.has_inf
                suggestions{end+1} = '检测到无穷值，需要数据预处理';
            end
        end
    end
    
    suggestions{end+1} = '联系数据提供方确认文件格式和规格';
end

function generate_diagnostic_report(diagnostic_results)
%% 生成诊断汇总报告
    
    report_filename = 'foct_diagnostic_report.txt';
    fid = fopen(report_filename, 'w');
    
    fprintf(fid, '=== FOCT文件诊断报告 ===\n');
    fprintf(fid, '生成时间: %s\n\n', datestr(now));
    
    total_files = length(diagnostic_results);
    not_found_count = 0;
    size_mismatch_count = 0;
    
    fprintf(fid, '诊断汇总:\n');
    fprintf(fid, '  总计文件: %d\n', total_files);
    
    for i = 1:length(diagnostic_results)
        result = diagnostic_results{i};
        
        if strcmp(result.status, 'not_found')
            not_found_count = not_found_count + 1;
            continue;
        end
        
        if ~result.size_match
            size_mismatch_count = size_mismatch_count + 1;
        end
    end
    
    fprintf(fid, '  文件不存在: %d\n', not_found_count);
    fprintf(fid, '  大小不匹配: %d\n', size_mismatch_count);
    fprintf(fid, '  正常文件: %d\n\n', total_files - not_found_count - size_mismatch_count);
    
    % 详细信息
    fprintf(fid, '详细诊断结果:\n');
    for i = 1:length(diagnostic_results)
        result = diagnostic_results{i};
        
        fprintf(fid, '\n--- 文件 %d: %s ---\n', i, result.filename);
        
        if strcmp(result.status, 'not_found')
            fprintf(fid, '状态: 文件不存在\n');
            continue;
        end
        
        fprintf(fid, '文件大小: %d 字节 (%.2f MB)\n', ...
                result.file_size, result.file_size/1024/1024);
        fprintf(fid, '大小匹配: %s\n', logical_to_string(result.size_match));
        
        if isfield(result, 'possible_formats') && ~isempty(result.possible_formats)
            fprintf(fid, '可能格式:\n');
            for j = 1:min(3, size(result.possible_formats, 1))
                fmt = result.possible_formats(j, :);
                fprintf(fid, '  %dx%dx%d (%s)\n', fmt{1}, fmt{2}, fmt{3}, fmt{4});
            end
        end
        
        if isfield(result, 'suggestions')
            fprintf(fid, '修复建议:\n');
            for j = 1:length(result.suggestions)
                fprintf(fid, '  %d. %s\n', j, result.suggestions{j});
            end
        end
    end
    
    fprintf(fid, '\n推荐的修复工具:\n');
    fprintf(fid, '1. fix_failed_foct_files.m - 自动修复非标准格式\n');
    fprintf(fid, '2. batch_foct_converter.m - 重新批量转换\n');
    fprintf(fid, '3. 手动检查文件完整性和格式规范\n');
    
    fclose(fid);
end

function str = logical_to_string(val)
%% 将逻辑值转换为中文字符串
    if val
        str = '是';
    else
        str = '否';
    end
end